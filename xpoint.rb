# Xpoint - Protótipo em Ruby Atualizado e Corrigido

require 'sqlite3'
require 'date'
require 'gruff'

# Configuração do banco de dados
DB = SQLite3::Database.new 'xpoint.db'
DB.results_as_hash = true

# Criação das tabelas
DB.execute <<-SQL
  CREATE TABLE IF NOT EXISTS projects (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    weekly_hours INTEGER NOT NULL,
    work_days TEXT NOT NULL,
    tags TEXT
  );

  CREATE TABLE IF NOT EXISTS time_entries (
    id INTEGER PRIMARY KEY,
    project_id INTEGER,
    date TEXT NOT NULL,
    start_time TEXT NOT NULL,
    end_time TEXT,
    is_pause BOOLEAN DEFAULT 0,
    FOREIGN KEY (project_id) REFERENCES projects(id)
  );

  CREATE TABLE IF NOT EXISTS edits_history (
    id INTEGER PRIMARY KEY,
    time_entry_id INTEGER,
    edit_type TEXT NOT NULL,
    old_value TEXT,
    new_value TEXT,
    edit_date TEXT NOT NULL,
    FOREIGN KEY (time_entry_id) REFERENCES time_entries(id)
  );
SQL

class Project
  def self.create(name, weekly_hours, work_days, tags = nil)
    DB.execute("INSERT INTO projects (name, weekly_hours, work_days, tags) VALUES (?, ?, ?, ?)",
               [name, weekly_hours, work_days.join(','), tags])
    DB.last_insert_row_id
  end

  def self.all
    DB.execute("SELECT * FROM projects")
  end

  def self.find(id)
    DB.execute("SELECT * FROM projects WHERE id = ?", [id]).first
  end

  def self.daily_hours(id)
    project = find(id)
    return 0 if project.nil?

    weekly_hours = project['weekly_hours']
    work_days = project['work_days'].split(',').count
    daily_hours = (weekly_hours.to_f / work_days).ceil
    daily_hours
  end

  def self.input_reference
    puts "Referência para criar um novo projeto:"
    puts "Nome do projeto: string (ex: 'Projeto A')"
    puts "Horas semanais: inteiro (ex: 40)"
    puts "Dias de trabalho: array de strings (ex: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'])"
    puts "Tags (opcional): string com tags separadas por vírgula (ex: 'desenvolvimento,web')"
    puts "\nExemplo de uso:"
    puts "Project.create('Projeto A', 40, ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'], 'desenvolvimento,web')"
  end
end

class TimeEntry
  def self.create(project_id, date, start_time, end_time = nil, is_pause = false)
    DB.execute("INSERT INTO time_entries (project_id, date, start_time, end_time, is_pause) VALUES (?, ?, ?, ?, ?)",
               [project_id, date, start_time, end_time, is_pause ? 1 : 0])
    DB.last_insert_row_id
  end

  def self.update(id, end_time)
    old_entry = DB.execute("SELECT * FROM time_entries WHERE id = ?", [id]).first
    DB.execute("UPDATE time_entries SET end_time = ? WHERE id = ?", [end_time, id])
    record_edit(id, 'end_time', old_entry['end_time'], end_time)
  end

  def self.for_project(project_id, start_date, end_date = nil)
    if end_date
      DB.execute("SELECT * FROM time_entries WHERE project_id = ? AND date BETWEEN ? AND ? ORDER BY date, start_time", [project_id, start_date, end_date])
    else
      DB.execute("SELECT * FROM time_entries WHERE project_id = ? AND date = ? ORDER BY start_time", [project_id, start_date])
    end
  end

  def self.record_edit(time_entry_id, edit_type, old_value, new_value)
    DB.execute("INSERT INTO edits_history (time_entry_id, edit_type, old_value, new_value, edit_date) VALUES (?, ?, ?, ?, ?)",
               [time_entry_id, edit_type, old_value, new_value, DateTime.now.to_s])
  end

  def self.input_reference
    puts "Referência para criar uma nova entrada de tempo:"
    puts "ID do projeto: inteiro (ex: 1)"
    puts "Data: string no formato 'YYYY-MM-DD' (ex: '2024-03-08')"
    puts "Hora de início: string no formato 'HH:MM' (ex: '09:00')"
    puts "Hora de fim (opcional): string no formato 'HH:MM' (ex: '12:00')"
    puts "É pausa?: booleano (true ou false, padrão é false)"
    puts "\nExemplo de uso:"
    puts "TimeEntry.create(1, '2024-03-08', '09:00', '12:00')"
    puts "TimeEntry.create(1, '2024-03-08', '12:00', '13:00', true) # Pausa para almoço"
  end
end

class Report
  def self.daily_summary(project_id, date)
    entries = TimeEntry.for_project(project_id, date)
    total_time = 0
    pause_time = 0

    entries.each do |entry|
      start_time = Time.parse(entry['start_time'])
      end_time = entry['end_time'] ? Time.parse(entry['end_time']) : Time.now
      duration = (end_time - start_time) / 3600.0 # Convert to hours

      if entry['is_pause'] == 1
        pause_time += duration
      else
        total_time += duration
      end
    end

    work_time = total_time - pause_time
    expected_time = Project.daily_hours(project_id)

    status = if work_time.round(2) == expected_time
               'blue'
             elsif work_time > expected_time
               'green'
             else
               'red'
             end

    {
      date: date,
      total_time: total_time.round(2),
      work_time: work_time.round(2),
      pause_time: pause_time.round(2),
      expected_time: expected_time,
      status: status
    }
  end

  def self.weekly_summary(project_id, start_date)
    end_date = Date.parse(start_date) + 6
    entries = TimeEntry.for_project(project_id, start_date, end_date.to_s)
    
    daily_summaries = (Date.parse(start_date)..end_date).map do |date|
      daily_summary(project_id, date.to_s)
    end

    total_work_time = daily_summaries.sum { |summary| summary[:work_time] }
    total_pause_time = daily_summaries.sum { |summary| summary[:pause_time] }
    expected_time = Project.daily_hours(project_id) * 7

    {
      start_date: start_date,
      end_date: end_date.to_s,
      total_work_time: total_work_time.round(2),
      total_pause_time: total_pause_time.round(2),
      expected_time: expected_time,
      daily_summaries: daily_summaries
    }
  end

  def self.monthly_summary(project_id, year, month)
    start_date = Date.new(year.to_i, month.to_i, 1)
    end_date = start_date.next_month - 1
    entries = TimeEntry.for_project(project_id, start_date.to_s, end_date.to_s)

    weekly_summaries = []
    current_date = start_date
    while current_date <= end_date
      weekly_summaries << weekly_summary(project_id, current_date.to_s)
      current_date += 7
    end

    total_work_time = weekly_summaries.sum { |summary| summary[:total_work_time] }
    total_pause_time = weekly_summaries.sum { |summary| summary[:total_pause_time] }
    expected_time = Project.daily_hours(project_id) * end_date.day

    {
      year: year,
      month: month,
      total_work_time: total_work_time.round(2),
      total_pause_time: total_pause_time.round(2),
      expected_time: expected_time,
      weekly_summaries: weekly_summaries
    }
  end

  def self.generate_daily_chart(project_id, date)
    summary = daily_summary(project_id, date)
    
    g = Gruff::Pie.new
    g.title = "Daily Time Distribution for #{date}"
    g.data('Work Time', summary[:work_time])
    g.data('Pause Time', summary[:pause_time])
    g.write("daily_chart_#{project_id}_#{date}.png")
  end

  def self.generate_weekly_chart(project_id, start_date)
    summary = weekly_summary(project_id, start_date)
    
    g = Gruff::Bar.new
    g.title = "Weekly Work Time vs Expected (#{summary[:start_date]} to #{summary[:end_date]})"
    summary[:daily_summaries].each do |daily|
      g.data(daily[:date], [daily[:work_time], Project.daily_hours(project_id)])
    end
    g.labels = { 0 => 'Work Time', 1 => 'Expected' }
    g.write("weekly_chart_#{project_id}_#{start_date}.png")
  end

  def self.generate_monthly_chart(project_id, year, month)
    summary = monthly_summary(project_id, year, month)
    
    g = Gruff::Line.new
    g.title = "Monthly Work Time Trend (#{year}-#{month})"
    work_time_data = []
    expected_time_data = []
    
    summary[:weekly_summaries].each_with_index do |weekly, index|
      work_time_data << weekly[:total_work_time]
      expected_time_data << weekly[:expected_time]
      g.labels[index] = "Week #{index + 1}"
    end
    
    g.data('Work Time', work_time_data)
    g.data('Expected Time', expected_time_data)
    g.write("monthly_chart_#{project_id}_#{year}_#{month}.png")
  end

  def self.input_reference
    puts "Referência para gerar relatórios e gráficos:"
    puts "\nRelatório Diário:"
    puts "Report.daily_summary(project_id, date)"
    puts "Ex: Report.daily_summary(1, '2024-03-08')"
    puts "\nRelatório Semanal:"
    puts "Report.weekly_summary(project_id, start_date)"
    puts "Ex: Report.weekly_summary(1, '2024-03-04')"
    puts "\nRelatório Mensal:"
    puts "Report.monthly_summary(project_id, year, month)"
    puts "Ex: Report.monthly_summary(1, 2024, 3)"
    puts "\nGerar Gráfico Diário:"
    puts "Report.generate_daily_chart(project_id, date)"
    puts "Ex: Report.generate_daily_chart(1, '2024-03-08')"
    puts "\nGerar Gráfico Semanal:"
    puts "Report.generate_weekly_chart(project_id, start_date)"
    puts "Ex: Report.generate_weekly_chart(1, '2024-03-04')"
    puts "\nGerar Gráfico Mensal:"
    puts "Report.generate_monthly_chart(project_id, year, month)"
    puts "Ex: Report.generate_monthly_chart(1, 2024, 3)"
  end
end

# Exemplo de uso
# project_id = Project.create('Projeto A', 40, ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'], 'tag1,tag2')
# TimeEntry.create(project_id, '2024-03-08', '09:00', '12:00')
# TimeEntry.create(project_id, '2024-03-08', '12:00', '13:00', true) # Pausa para almoço
# TimeEntry.create(project_id, '2024-03-08', '13:00', '18:00')
# puts Report.daily_summary(project_id, '2024-03-08')
# Report.generate_daily_chart(project_id, '2024-03-08')

# Para ver as referências de entrada:
# Project.input_reference
# TimeEntry.input_reference
# Report.input_reference