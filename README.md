# Xpoint - Controle de Ponto para Equipes Ágeis

## Descrição e Objetivos

Xpoint é uma aplicação de controle de ponto projetada especificamente para equipes ágeis. Ela permite um gerenciamento flexível do tempo de trabalho, adequando-se às necessidades de projetos dinâmicos e equipes com horários variáveis.

### Principais Características

- Cadastro de projetos com definição de horas semanais e dias de trabalho
- Registro flexível de entrada e saída, incluindo pausas
- Cálculo automático de horas trabalhadas por dia, semana e mês
- Visualização de horas positivas, negativas ou dentro do esperado
- Geração de relatórios e gráficos para análise de tempo

## Tecnologias

### Protótipo Inicial
- **Ruby**: Linguagem principal para o desenvolvimento do protótipo
- **SQLite**: Banco de dados local para armazenamento de informações
- **Gruff**: Biblioteca para geração de gráficos

### Versão Final Planejada
- **Flutter**: Framework para desenvolvimento da interface gráfica multiplataforma
- **SQflite** ou **Hive**: Para armazenamento local de dados no aplicativo Flutter
- **Local Authentication Plugin**: Para autenticação simples usando biometria ou senha
- **Charts Flutter** ou **fl_chart**: Para criação de gráficos nativos no Flutter

## Estrutura do Projeto

O protótipo em Ruby consiste em três classes principais:

1. **Project**: Gerencia informações sobre os projetos
2. **TimeEntry**: Lida com os registros de tempo
3. **Report**: Gera relatórios e gráficos baseados nos dados de tempo

## Funcionalidades Detalhadas

### Cadastro de Projetos
- Nome do projeto
- Horas semanais previstas
- Dias de trabalho selecionáveis
- Tags para categorização

### Registro de Tempo
- Início e fim de atividades
- Registro de pausas
- Cálculo automático de horas trabalhadas

### Relatórios
- Diários
- Semanais
- Mensais

### Visualizações Gráficas
- Gráfico de pizza para distribuição diária de tempo
- Gráfico de barras para comparação semanal
- Gráfico de linha para tendências mensais

### Análise de Tempo
- Comparação entre tempo planejado e tempo real
- Identificação de horas extras ou faltantes
- Códigos de cor para rápida visualização (azul, verde, vermelho)

## Melhorias Recentes

1. **Referências de Entrada**: Adição de métodos `input_reference` para guiar os usuários no uso correto das classes e métodos.

2. **Relatórios Expandidos**: Implementação de relatórios semanais e mensais além dos diários já existentes.

3. **Geração de Gráficos**: Integração da biblioteca Gruff para criar visualizações gráficas dos dados de tempo.

4. **Cálculos de Tempo Aprimorados**: Melhorias nos cálculos de tempo total, tempo de trabalho e pausas em todos os níveis de relatório.

5. **Flexibilidade na Consulta de Dados**: Atualização do método `for_project` para aceitar intervalos de datas, facilitando a geração de relatórios mais complexos.

## Como Usar

### Instalação
1. Certifique-se de ter Ruby instalado em seu sistema.
2. Clone este repositório.
3. Instale as dependências necessárias:
   ```
   gem install sqlite3 gruff
   ```

### Exemplos de Uso

#### Criar um Projeto
```ruby
Project.create('Projeto A', 40, ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'], 'desenvolvimento,web')
```

#### Registrar Tempo
```ruby
TimeEntry.create(1, '2024-03-08', '09:00', '12:00')
TimeEntry.create(1, '2024-03-08', '12:00', '13:00', true) # Pausa para almoço
TimeEntry.create(1, '2024-03-08', '13:00', '18:00')
```

#### Gerar Relatórios e Gráficos
```ruby
# Relatório diário
puts Report.daily_summary(1, '2024-03-08')
Report.generate_daily_chart(1, '2024-03-08')

# Relatório semanal
puts Report.weekly_summary(1, '2024-03-04')
Report.generate_weekly_chart(1, '2024-03-04')

# Relatório mensal
puts Report.monthly_summary(1, 2024, 3)
Report.generate_monthly_chart(1, 2024, 3)
```

### Referências de Entrada
Para ver instruções detalhadas sobre como usar cada classe:
```ruby
Project.input_reference
TimeEntry.input_reference
Report.input_reference
```

## Próximos Passos

1. Desenvolver a interface do usuário usando Flutter
2. Implementar autenticação local
3. Migrar o armazenamento de dados para SQflite ou Hive
4. Adicionar funcionalidade de exportação de relatórios para PDF
5. Implementar sistema de backup de dados
6. Criar testes automatizados para garantir a robustez do sistema

## Contribuição

Contribuições são bem-vindas! Por favor, sinta-se à vontade para submeter pull requests ou abrir issues para discutir melhorias ou relatar bugs.

## Licença

[Inserir informações de licença aqui]