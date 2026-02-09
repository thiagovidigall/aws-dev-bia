# Passo a Passo AWS

## Dia 1 - Manhã
- configurar o billing
  - criar um budget (orçamento de 5 dolares)
- mudar o idioma para ingles
- entrar no cloudshelll
- clonar o repositorio do github aws-dev-bia
  - entrar na pasta aws-dev-bia/scripts
  - rodar o ./validar_recursos_zona_a.sh
  - criar um novo sg para o bia-dev (acesso ao bia-dev, usar vpc padrao da nova conta)
    - vou dar acesso ao bia-dev (onde minha aplicação de teste vai rodar no navegador)
    - adicionar inbound (entrada), TCP, 3001, IPV4, Liberado par Todos 0.0.0.0
    - outbound não mexer - como nossa EC2 vai comunicar com serviços externos
  - criar role para acessar o bia-dev por SSM
    - rodar o script ($ ./scripts/criar_role_ssm.sh)
    - ou criar manualmente, adicionar um police para "AmazonSSMManagedInstanceCore" e o nome da role
  - criar EC2 para a zona A (lancar EC2 para a zona A)
    - rodar o script ( $ ./scripts/lancar_ec2_zona_a.sh )
    - ou criar instancia EC2 
      - escolher o nome bia-dev, amazon linux 2023, type t3.micro, key pair (não precisa, vai por ssm), network selecionar o sg bia-dev, 15gb, advance details AIM role-acesso-ssm e user data (selecionar na pasta de scripts do github "user_data_ec2_zona_a.sh")
  - Entrar na instancia EC2, conect por Session Manager (SSM), trocar para o usurio default
    - $ sudo su ec2-user
    - $ cd /home/ec2-user
    - Baixar o Kiro-CLI ( https://kiro.dev/docs/cli/installation/ )
      - $ ldd --version
      - $ curl --proto '=https' --tlsv1.2 -sSf 'https://desktop-release.q.us-east-1.amazonaws.com/latest/kirocli-x86_64-linux.zip' -o 'kirocli.zip'
      - $ unzip kirocli.zip
      - $ ./kirocli/install.sh
      - $ kiro-cli login --use-device-flow
      - Antes ( criar o profile.aws.amazon.com) ....
      - segue usando a primeira opçao: builder Id, copia o endereço e cola no navegador e pronto
      - kiro-cli  (para entrar no cli da AI)
      - para sair /q
    - Usando o Kiro-CLI
      - contexto - usar o contexto para delimitar os recursos
        - dentro da pasta .kyro tem a descricao do contexto nas pasta agents e rules
      - rodar o commando , kiro-cli --agent "bia"
    - Conectar a EC2 na conta do github
      - gerar a chave ssh com:
        - $ ssh-keygen
      - copiar a chave publica para o github dentro de ssh and gpg keys
      - testar a conexao
        - ssh -T git@github.com  
    - Baixar o repositorio 
      - git clone git@github.com:thiagovidigall/aws-dev-bia.git
    - Rodar o container docker
      - cd /home/ec2-user
      - cd aws-dev-bia
      - docker compose up -d
    - Vou na instancia EC2 para copiar o ip
      - ir no navegador e digitar http:ip.x.x.x:3001
    - Instalar o MCP agent do banco
      - https://github.com/crystaldba/postgres-mcp
      - copiar o conteudo do arquivos .kiro/mcp-db.json
      - colar em .kiro/agents/bia.json
      - $ nano .kiro/agents/bia.json
          - comandos do nano
            Ctrl + O → salvar
            Enter → confirmar
            Ctrl + X → sair
            Ctrl + W → procurar texto
            Ctrl + K → recortar linha
            Ctrl + U → colar linha
            Ctrl + Shift + v → colar do host para o browser ec2 dentro do promnt
            Alt + U → desfazer
            Alt + E → refazer
            Ctrl + G → ajuda
        $ python3 -m json.tool bia.json > tmp && mv tmp bia.json
      - cuidado com o nome da rede, se não especificado no compose.yml ele vai usar o nome
      da pasta + default no meu caso a pasta é aws-dev-bia entao vai ficar 
      --network=aws-dev-bia_default 
      - rodar o kiro-cli com o MCP que foi configurado
         - $ na raiz do projeto:
           - kiro-cli chat --agent "bia"
           - /q para sair do kiro
    Instalar o MCP agent do ec2
      - https://awslabs.github.io/mcp/servers/ecs-mcp-server/
      - uv venv
      - uv pip install awslabs.ecs-mcp-server
      - copiar o conteudo do arquivos .kiro/mcp-ecs.json
      - colar em .kiro/agents/bia.json
      - $ nano .kiro/agents/bia.json
      -  executar o kiro-cli:
        - primeiro voltar para a pasta raiz do projeto ( aws-dev-bia )
        - $ kiro-cli chat --agent "bia"
          - aqui digitar: lista para mim os meu clusters no ecs
  Conteinizar com ajuda da AI
    - prompt: eu gostaria de criar um novo dockerfile para o meu , seguindo a filosofia simples, pois estou fazendo uma demostração ao vivo, para ver se vc é capaz de nos ajudar, o meu problema roda externamente na port 3001, apois gerar o dockerfile, me passe a instrucao par rodar o meu container (nao sobreponha o que ja tenho na raiz do projeto)
      -saida:
        - ##### Build da imagem
          docker build -f Dockerfile.demo -t bia-demo .
        - ##### Executar o container (mapeando porta 3001)
          docker run -p 3001:3001 bia-demo
        - ##### Testar o health check
          curl http://localhost:3001/api/versao  
    - prompt: teste para mim
      - saida:
         ##### Build da imagem
        docker build -f Dockerfile.demo -t bia-demo .
        ##### Executar o container (mapeando porta 3001)
        docker run -p 3001:3001 bia-demo
        ##### Testar o health check
        curl http://localhost:3001/api/versao
        
  Trabalhando com IAM
    - tarefas:
      - roles para nossa ec2 de trabalho
      - testando permissoes: aws ecr describe-repositories
      - adicionando permissao para os serviços que vamos explirar
        - RDS, ECR, ECS, EC2
    - configurando o IAM, roles, achar a role "role-acesso-ssm" e adicionar polices
      - rdsfullaccess  ( para banco )
      - ecsfullaccess  ( para deploy - clusters )
      - ec2fullaccess  ( para trobleshoote, verificar security group )
      - ec2containerregistrypoweruser
    - verficando se as polices adicionadas estão funcinando
      - $ aws ecr describe-repositories
      - 



      












## Dia 1 - Tarde

#### Passo 1 - Abrir a instancia EC2 e verificar o seu ip publico (3.239.54.104)
- verificar como esta o docker
- $ docker ps
- pegar o ip da instancia por terminal
- $ curl ifconfig.me
- acessar o app que esta rodando na porta 3001 no browser com o ip publico
- http://3.239.54.104:3001
- status offline, pois front no ip public e api está no localhost
- o app esta dentro do ec2, publicado com docker, 
- o docker subiu o front, db, mas o dockerfile do projeto está apontando para api em localhost

##### Ajustando o dockerfile para api subir no ip public e não localhost
- $ nano Dockerfile  (troca o localhost para ip e salvar e sair)
- $ docker compose down
- $ docker compose build server  (criar uma nova imagem)
  - porque fazer um build, pq no compose.yml tenho os services 
- $ docker compose up -d
- o projeto subiu mas sem as tabelas temos rodar o migrate
- dentro do README.md tem esse passo
- $ docker compose exec server bash -c 'npx sequelize db:migrate' (agora vai persistir)
- acessar o agent para ver se ele consegue interagir
- $ kiro-cli chat --agent "bia"
  - prompt: verifique os registros que tenho na tabela de tarefas
  - $ docker compose down  (parar a bia na maquina de trabalho)

#### Passo 2 
- Ajustar o security group para criar um cluster ECS, ECR, RDS, bia-web...
- vamos manter a bia-dev com os nossos agentes (MCP Post/EC2)
- para o cluster criar a estrutura de sg, não fazer atraves de ips
  - para associar o RDS vamos criar o SG "bia-db"
  - para ... vamos criar o SG "bia-web" liberado para o mundo (0.0.0.0/0) na porta 80
    - vou precisar de um EC2 ?
  - para o primeiro EC2 temos o SG "bia-dev" liberado para o mundo na porta 80

##### Criar o bia-bd
- qual estrutura de comunicação eu preciso estabelecer no bia-db?
  - liberar porta de entrada (inbound) 5432 para permitir comunicação com o bia-web adicionar sg-bia-web na (rota), não colocar 0.0.0.0/0 e porta
    - mas porque o bia-web? aplicação/ instancia de produção 
    - aqui não tem responsabilidade de manutenção, migrates, ..., é roda o app
    - aqui é só aplicação, só a publição/produção, não podemos rodar comandos de banco 
  - ??? liberar porta de entrada (inbound) 5432 para permitir comunicação com o bia-dev
    - mas porque o bia-dev tambem? para que o agente possa continuar atuando/auxiliando em tarefa no banco
    - ele é responsavel por dar manutenção no bd, roda migrates, etc
  - Liberar o bia-dev usando o agente, usando trobleshoot, ele vai descobrir o problema de comunicação e adicionar o inbound para o bia-dev    

##### Usando o bia-dev
- ele vai rodar as migrates e interagir com o RDS
- mas em um ambiente real não preciso disso posso fazer tudo nas pipelines

##### Criar o RDS para MULTI-AZ
- em Aurora and RDS vai em criate database






## Recursos criados que tenho que deletar na zona para trabalho
1. uma instancia EC2
2. security groups (SGs)
 - bia-dev
 - bia-web
 - bia-db
3. um RDS database
4. 

## Sequencia pra a de configuração de recursos

- 1º VPC
- 2º Subnet
- 3º SG - Security Group (1-default conta nova)
  - dentro de EC2 -> Networks - SG
  - criar um novo sg
    - outbound - como a nossa maquina vai comunicar com serviços externos (não mexer para o sg bia-dev)
- 4º Role - acesso via SSM
  - dentro de AIM - Roles ( por default já existe 3 para um novo usuario )
  - criar uma nova role ( create role )
    - adicionar uma police para o agent SSM funcionar (filtrar ssmman), escolher "AmazonSSMManagedInstanceCore"
    - adicionado 4 polices (rdsfullaccess,ecsfullaccess,ec2fullaccess,ec2containerregistrypoweruser)
- 5º EC2 instance usando o sg e um script para subir a maquina com os recurso para publicar o web app
- 6º Entrar na

