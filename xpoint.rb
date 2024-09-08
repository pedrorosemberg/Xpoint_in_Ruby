# Xpoint - Protótipo em Ruby

require 'sqlite3'
require 'date'

# Configuração do banco de dados
DB = SQLite3::Database.new 'xpoint.db'

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

    weekly_hours = project[2]
    work_days = project[3].split(',').count
    daily_hours = (weekly_hours.to_f / work_days).ceil
    daily_hours
  end
end

class TimeEntry
  def self.create(project_id, date, start_time, end_time = nil, is_pause = false)
    DB.execute("INSERT INTO time_entries (project_id, date, start_time, end_time, is_pause) VALUES (?, ?, ?, ?, ?)",
               [project_id, date, start_time, end_time, is_pause ? 1 : 0])
  end

  def self.update(id, end_time)
    old_entry = DB.execute("SELECT * FROM time_entries WHERE id = ?", [id]).first
    DB.execute("UPDATE time_entries SET end_time = ? WHERE id = ?", [end_time, id])
    record_edit(id, 'end_time', old_entry[4], end_time)
  end

  def self.for_project(project_id, date)
    DB.execute("SELECT * FROM time_entries WHERE project_id = ? AND date = ? ORDER BY start_time", [project_id, date])
  end

  def self.record_edit(time_entry_id, edit_type, old_value, new_value)
    DB.execute("INSERT INTO edits_history (time_entry_id, edit_type, old_value, new_value, edit_date) VALUES (?, ?, ?, ?, ?)",
               [time_entry_id, edit_type, old_value, new_value, DateTime.now.to_s])
  end
end

class Report
  def self.daily_summary(project_id, date)
    entries = TimeEntry.for_project(project_id, date)
    total_time = 0
    pause_time = 0

    entries.each do |entry|
      start_time = Time.parse(entry[3])
      end_time = entry[4] ? Time.parse(entry[4]) : Time.now
      duration = (end_time - start_time) / 3600.0 # Convert to hours

      if entry[5] == 1 # is_pause
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

  # Adicione métodos para relatórios semanais e mensais aqui
end

# Exemplo de uso
# Project.create('Projeto A', 40, ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'], 'tag1,tag2')
# TimeEntry.create(1, '2024-03-08', '09:00', '12:00')
# TimeEntry.create(1, '2024-03-08', '12:00', '13:00', true) # Pausa para almoço
# TimeEntry.create(1, '2024-03-08', '13:00', '18:00')
# puts Report.daily_summary(1, '2024-03-08')