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
    - Baixar o Kiro-CLI ( [https://kiro.dev/docs/cli/installation/](https://kiro.dev/docs/cli/installation/) )
      - $ ldd --version
      - $ curl --proto '=https' --tlsv1.2 -sSf '[https://desktop-release.q.us-east-1.amazonaws.com/latest/kirocli-x86_64-linux.zip](https://desktop-release.q.us-east-1.amazonaws.com/latest/kirocli-x86_64-linux.zip)' -o 'kirocli.zip'
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
        - ssh -T [git@github.com](mailto:git@github.com)
    - Baixar o repositorio 
      - git clone [git@github.com](mailto:git@github.com):thiagovidigall/aws-dev-bia.git
    - Rodar o container docker
      - cd /home/ec2-user
      - cd aws-dev-bia
      - docker compose up -d
    - Vou na instancia EC2 para copiar o ip
      - ir no navegador e digitar http:ip.x.x.x:3001
    - Instalar o MCP agent do banco
      - [https://github.com/crystaldba/postgres-mcp](https://github.com/crystaldba/postgres-mcp)
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
    - [https://awslabs.github.io/mcp/servers/ecs-mcp-server/](https://awslabs.github.io/mcp/servers/ecs-mcp-server/)
    - uv venv
    - uv pip install awslabs.ecs-mcp-server
    - copiar o conteudo do arquivos .kiro/mcp-ecs.json
    - colar em .kiro/agents/bia.json
    - $ nano .kiro/agents/bia.json
    - executar o kiro-cli:
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

## Dia 1 - Tarde

#### Passo 1 - Abrir a instancia EC2 e verificar o seu ip publico (3.239.54.104)

- verificar como esta o docker
- $ docker ps
- pegar o ip da instancia por terminal
- $ curl ifconfig.me
- acessar o app que esta rodando na porta 3001 no browser com o ip publico
- [http://3.239.54.104:3001](http://3.239.54.104:3001)
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

#### Passo 2 - Criar os SGs

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

#### Passo 3 - Criar o RDS para MULTI-AZ

- em Aurora and RDS vai em criate database
- marcar e desmarcar as opções:

1. postgresql 17.6R
2. dev/test ou Sandbox (não precisa de dar upgrade no plano agora)
3. single-AZ (Multi-AZ só no plano pago)
4. colocar nome da instancia "bia"
5. marcar para gerar credentias (vai ser mostrado ao final, tem que salvar a senha)
6. instancia escolher t3.micro
7. disco com 20gb
8. desmarcar "enable storage autoscaling"
9. security group deve escolher o "bia-db" apenas
10. desmarcar monitoramento "Enable Performace Insights" e deixar o "Standard"
11. dexar em branco o nome inicial do banco, pois vai ser setado ao rodar a migrations
12. desmarcar backup "Enable automated backup"
13. deixar marcado (já vem com default) "Enable encryp..."
14. pegar a senha no final da criação
15. pegar a url

#### Passo 4 - Criar o ECR - Elastic Container Registry

1. criar o repositorio "bia"
2. voltar para a instancia EC2 e executar o commando "$ docker images", achar a imagem bia-server
3. imagem está local (dentro do ec2), temos que mandar para o ECR
4. dentro ECR entrar em "view push commands" para pegar o endereço "600161851259.dkr.ecr.us-east-1.amazonaws.com" e sigo os comandos ou uso o script da pasta "scripts/ecs/unix/

build.sh"
5. dentro do ec2 pasta "aws-dev-bia" copio o script para a raiz
6. $ cp scripts/ecs/unix/build.sh .
7. $ nano build.sh para atualizar a variavel "ECR_REGISTRY" com o endereço do ECR
8. $ chmod +x build.sh  (dou permissão para poder exercutar)
9. Deletar depois - faz cobrança por imagem armazenada nele (gb/mes ou transferencia p/ fora push)

#### Passo 5 - Usando o ECS - Elastic Container Service

1. criar o cluster (poder computacional, precisa colocar maquinas nele, precisa colocar o serviço para as maquinas rodarem)
  - dentro de ECS -> cluster - criate cluster
  1. escolher opcao "Fargate and Self-managend instances"
  2. trabalhar com modelo que dizemos qtas instancias vamos querer
  3. escolher create a new auto scaling group
  4. escolher Fargate and Self-managed instances
  5. escolher on-demand
  6. escolher tipo t3.micro
  7. criar uma default role
  8. Desired capacity 1 - 1
  9. escolher zonas Network settings -> zonas "a" e "b", remover as outras
  10. escolher o SG "bia-web" como no desenho, remover os outros
  11. tambem foi criada uma role default para o cluster, antes só tinhamos a role-acesso-ssm
    - agora tem uma nova com prefixo ecs
  12. para deletar o cluster
    - primeiro entrar em services e deletar todos os services
    - segundo na aba tasks dar um stop
    - vai em EC2 - depois em loadbalancer e deletar o loadbalancer do ecs
    - se for um Fargate não tem EC2 para apagar
    - se for um EC2 tem que encerrar em EC2: instancias + Auto Scaling groups + Launch Templates
    - tb verificar o CloudFormation Stacks tem que ficar zerada
    - ficou zerado tudo em Auto Scaling groups + Launch Templates
    - outras coisas que podem ficar par traz e trazem custos
      - Amazon ECR
      - CloudWatch Logs
    - revisão confirme que:
      Não existe Service ativo
      Não existe Task rodando
      Não existe Load Balancer
      Não existe Target Group
      Não existe EC2 / ASG
      Cluster deletado
      ECR limpo (opcional)
2. criar task definition (uma task é um container, mas podemos ter mais de um container por task)
  - para criar a task definitio ir no menu as esquerda e clicar em "Task Definition" depois "create new task definition"
  - definir o nome para family: "task-def-bia"
  - marcar para trabalhar com instancias EC2 "Amazon EC2 instances"
  - escolher network mode por padrão escolher "bridge"
  - em task size, apagar CPU e apagar o conteudo de Memory
  - dentro da aba "Container"
    - em "Name" colocar "bia"
    - em "imagem URI" temos que entrar em ECR e marcar e copiar a URI (latest)
    - em "Host port" onde vai rodar a aplicação "Host port=80" e "container port=8080" e port-name "qqer um"
    - em "CPU=1" e "Memory soft limit = 0,4" o resto deixa em branco
    - em "Environment variables" pegar do compose.yml dentro do "bia-dev" ou do github
      - $ nano compose.yml
      - adicinar as variaveis:
      DB_USER: postgres
      DB_PWD: senha copiada qdo subiu o RDS
      DB_HOST: ir no RDS e copiar o nome do host
      DB_PORT: 5432
    - clicar em criate 
    - apos criado achar a opção de "Deploy" e dentro dele "create service"
      - em "service name" colocar "service-bia"
      - em "Launch type" escolher depois "EC2"      
      - em "deploynment configuration" escolher "Replica"
      - em "Availability Zone rebalancing" não faz sentido deixar marcado pois só temos 1 task
      - em depolyements stategy deixar marcado "Rolling update" ele vai substituindoas tasks gradualmente      
      - escolher Min running tasks % colocar 0
      - escolher Max 100
      - desmarcar Deployment failure detection  Info, pois qdo der erro vai parar, daí conseguimos ver o que aconteceu
      - em "Task placement" deixar por padrão espalhar as tasks na AZ disponiveis
3. criar o service  (responsavel por lançar os container as "tasks"), ele é o task definition (primo do compose)

- o "task definition" muda um pouquinho do compose pois terá informações da imagem, variáveis de ambiente, e fornecer o recurso computacional que vai ser alocado.
- acesso ao serviço disponivel: [http://3.239.247.28/](http://3.239.247.28/)

1. estabelecar comunicação da bia-dev (maquina de trabalho) para bia-db e rodar o migrate para criação das tabelas
  $ nano compose.yml
  - ajustar o "environment"
    - db_pwd: .... colocar o psw do rds
    - db_host: ... colocar o endereço do rds
     $ docker ps
     $ docker compose down
     $ docker compose up -d
     $ comando para rodar a migrate dentro do README.md, mas eu não crie comunicacao (sg do bia db aceitando o bia-dev)
  - docker compose exec server bash -c 'npx sequelize db:migrate'
  - para resolver vamos usar o AI para criar essa comunicação
  - kiro-cli chat --agent "bia"
  - prompt: estou tentando rodar as migrates que eu tenho no projeto para o meu banco no rds, mas esta acontecendo uma demora absurda. consegue me ajudar a identificar o que pode estar acontecendo? estou tentando rodar esse comando: docker compose exec server bash -c 'npx sequelize db:migrate'
2. Fazer o deploy dentro do bia-dev (antes fizemos o migrate no RDS)

- alterar o texto do botao html dentro do bia-dev
  - ir ate AddTask.jsx dentro do clent/scr/components
- alterar o endereço para a instancia do ECS
  - nano Dockerfile, altero o ip para o novo ip da instancia da ECS
    - nao tem a porta 3001, apenas o endereço ip sem barra tb
- roda o script de build
  - $ cat build.sh
  - $ nao preciso dar o comando de build pois o deploysh faz (./build.sh)
  - $ cp scripts/ecs/unix/deploy.sh .
  - $ nano deploy
  $ alterar o [cluster] e [service] para cluster-bia e service-bia sem os []
  - $ chmod +x deploy.sh
  - $ ./deploy.sh
  - se for no cluster (ECS), dentro de service, tem aba deploynments para aconpanhar o processo
  - ser for (ECR) dá para ver as duas imagens uma as 15h e outra as 22h
- dispara um push para o ECR, depois dispara um deploy para o ECS
- problema de deploy pois um sobrepoe ao outro

1. Fazer o versionamento do deploy com AI

- cada deploy deve guardar task definitions com as informações
  - entao dentro de ECS e depois Task definitions deve ser incrementado ex: task-def-bia:4, depois task-def-bia:6, ...
- $ prompt: estou precisando de um rotina de deploy que não sobreponha a que eu já tenho, quero que essa rotina de deploy seja simples, mas permita que eu trabalhe com versionamento no ECS. Eu preciso trabalhar com commit hash para criar tags das minhas versoes no ECR e com isso voce vai gerar uma task definition para cada uma delas e realizar o deploy no ECS. Analise o que precise ser feito para que eu veja antes de estar tudo ok.
- depois que ele rodar tudo
- $ crie um readme explicando sobre o novo deploy que vc criou
- $ o nome do cluster é cluster-bia e do meu service é service-bia... veja tambem o nome da minha task definition
- $ vc pode fazer o primeiro deploy para mim?
- $ git add .
- $ git commit -m "add new deploy"

1. Configuração de dominio ( Route 53 e ACM/Certificate Manager)

- Route 53 - controle do dominio e subdominio, entrada dos DNS
  - criar uma hosted zones, e pegar os endereços ns e atualizar lá no registro.br
- ACM - certificado digital para https
  - criar o certificado no ACM e autorizar no Route 53 atraves de entradas DNS
  - ele monitora as entradas e fala ele esta querendo entrar no dominio ele é o dono, então vai
  - dentro do acm, criar um request "request public certificate"
  - colocar o "fully qualified domain name" específico bia.devblue.com.br ou *.devblue.com.br para resolver qualquer coisa dentro do devblue
  - 

1. revisão do dia 1

- prompt: forneça um diagnostico simples da minha aplicação, confirmando se ela esta rodando perfeitamente no ecs

## Dia 2  - Manhã

#### Passo 1 - Security groups para alta disp9onivilidade

- criar o sg "bia-alb" com all TCP apenas para o ALB, para comunicar com o novo sg "bia-ec2"
  - add 1 inbound rules type http (porta 80),  source type ipv4, 0.0.0.0/0, liberado geral para fora
  - add 1 inbound rules type https (porta 443), source type ipv4, 0.0.0.0/0 liberado geral para fora
- criar o sg "bia-ec2"
  - add 1 inbound rules type "all tcp" para o source custom sg "bia-alb", liberado tudo para o "bia-alb"
- alterar o sg "bia-db" para aceitar trafego (inbound) do "bia-ec2"
  - add 1 inbound rules type "postgres" para o source custom sg "bia-ec2", liberado banco para o "bia-ec2"

#### Passo 2 - ALB - Target group

- ALB - load balanced tem um listener ( para escutar a porta 80 ) e daí manda para o target group
  - Target group vai rotear os trafego para as instancias EC2 que fazem parte do cluster
    - o tg encaminha as requisicoes para as instancias ec2
    - caso uma das instancia estiver fazendo deploy o tg deve parar de mandar requisicoes para aquela instancia, qual tempo devo drenar as conexoes ate que ela morra (tem que vc quer deixar o fluxo aberto (padrao 300), vou deixar 30s)
  - tambem para as tasks (containers)
  - comunicação all tcp com as portas 80 e 443 (https)
- Ir em Ec2 -> Load Balancing -> load Balancers
  - create load banlancer e escolher http e https
  - "definir name bia-alb", internet-facing, ipv4, escolher uma vpc ou (default), 
  - marcar zona a e b
  - escolher o sg "bia-alb"
  - vai mandar para onde? target group (criar um ...)
    - selecionar o target type instancis  (Ec2)
    - name "tg-bia"
    - tudo padrao, next, next, create ..
    - depois de criado, vai na aba horizontal "Attributes"

#### Passo 3 - Remover o cluster anterior e criar um novo

- abrir o ECS e marcar o "cluster-bia"
  - primeiro ir na aba horizontal "service" e deletar o service (marcar forçar)
  - segundo ir para o cluster e deletar o cluster
  - criar novo cluster
    - colocar name "cluster-bia-alb"
    - selecionar infrastructure: fargate and self-managed
    - create new auto scaling
    - on-demand
    - amazon linux 2023 + t3.micro
    - ec2 instance selecionar "ecsInstanceRole"
    - Minimum 2 e Maximum 2
    - vpc default com subnet a e b
    - create ( vai conter dentro de infraestructure 2 instancia de ec2)
  - criar task definition
    - seleciona a "task-def-bia" e seleciona a ultima revisão
    - dai selecionar "create new revision json" e ajustar o json
      - "family": "task-def-bia-alb",
      - "name": "porta-aleatoria",
      - "hostPort": 0,
      - "awslogs-group": "/ecs/task-def-bia-alb",
      - salvar, dai escolher "deploy" e "create service"
    - dentro da criação do service
      - name "service-bia-alb"
      - compute options  "Launch type" para EC2      
      - Scheduling strategy "Replica" para "2"
      - desmarcar o "Turn on Availability Zone rebalancing"
      - Deployment strategy "Rolling update"  "50 e "100"
      - desabilitar o "Deployment failure detection  Info"
      - marcar "Use load balancing"
      - selecionar vpc (padrao)
      - marcar "Load balancer type"
      - Container
        - aqu- eu me perdi no vido é 8080:8080 e o meu ficou 80:8080
      - Application Load Balancer use "Use an existing load balancer" e seleciona "bia-alb"
      - Listener escolher "Use an existing listene" e padrao "HTTP:80"
      - target grupo selecionar o "tg-bia"
      - "Task placement Info" escolher "AZ balanced spread"
      - create, daí ele vai lançar duas tasks automaticamento depois que o seviço foi criado
    - Como testar?
      - vai em Load Balancers "bia-alb" e copia o dns e coloca no navegador
        - Load balancers [http://bia-alb-2034249656.us-east-1.elb.amazonaws.com/](http://bia-alb-2034249656.us-east-1.elb.amazonaws.com/)

#### Passo 4 - Bia com alta disponibilidade -

- Acessar o app pelo ALB
  - vai em Load Balancers "bia-alb" e copia o dns e coloca no navegador
    - Load balancers [http://bia-alb-2034249656.us-east-1.elb.amazonaws.com/](http://bia-alb-2034249656.us-east-1.elb.amazonaws.com/)
- Explorar o resource map
  - EC2 -> load balancers -> bia-alb -> 
    - aba horizontal -> "Resource map"
      - mostra o fluxo que esta acontecendo saindo do loadbalane até nossas tasks (listener->regra padrao(semr egra)->target group->roteamento do tráfego (rotas))
      - mostra que o ambiente está saudável
      - 
  - EC2 -> target Groups -> tg-bia
    - mostra 2 instancias como "healthy"
    - mostra a distribuição por AZ (zona) e mostra se está saudável
- Fazer o deploy ajustando rota no Dokerfile
  - copiar o endereço do aplication load balance
  - ir em instancias e conectar na bia-dev (vai ser nela que vou alterar os scripts de deploy)
  - editar o dockerfile
    - $ nano /aws-dev-bia/Dockerfile, trocar o endereço [http://bia-alb-2034249656.us-east-1.elb.amazonaws.com](http://bia-alb-2034249656.us-east-1.elb.amazonaws.com)
    - $ nano deploy.sh   # mudar para o cluster-bia-alb e mudar o service par service-bia-alb
      - o script de deploy.sh esta simples e trabalha só com latest, temos que ir no ECS e depois no task definition para ver onde ele está apontando
      - abrir o "task-def-bia-alb", e clinar na ultima revision
      - criar "new revision", dentro achar "Image URI" e alterar o final para "...bia:latest" e "create"
      - depois vai em "deploy" e dentro escolher "update service" e depois rolar a tela para baixo e "update"
      - apos alterações voltar para o "bia-dev" e execuptar o script "$ ./deploy.sh"
    - $ ./deploy.sh  
    - se ficar preso o console na hora do deploy usar :"q" para sair
    - ir no ECR e ver que a ultima versão estara escrito "latest" com a data da execução
    - quero ver o deploy vou em ECS -> Clusters -> cluster-bia-alb -> Services -> service-bia-alb - aba H "Deployment"
    - quero ver a disponibilidade do deploy via script simples
      - entrar no "bia-dev"
      - vou abrir uma instancia e entrar na pasta home com usuario "ec2-user" depois na pasta "aws-dev-bia"      
      - $ cp scripts/ecs/unix/check-disponibilidade.sh
      - $ ./check-disponibilidade.sh
    - quero fazer um teste e atualizar o botão da app e ver se ela vai cai e o que vai acontecer
    - para isso 
      - abrir 2 terminais da bia-dev
        - na primeio deixo preparado para disparar o "./check..."
        - no segundo atualizo o botão e dou um deploy
        - endereço [http://bia-alb-2034249656.us-east-1.elb.amazonaws.com/api/versao](http://bia-alb-2034249656.us-east-1.elb.amazonaws.com/api/versao) uso como healfycheck
        - para acompanhar na AWS, podemos ver direto no ECS - cluster - "cluster-bia-alb"/"service-bia-alb"
          - em Service revisions (2) 
            - no Target (versão nova/destino) vai ter 1 Requested (0 - Running)
            - no Source (versao antiga/fonte) vai ter 1 Requested (1 - Running)
            - Obs ( Antes de disparar)
              - 7649397389232491386|View tasks-Target-2 Requested-2 Running-0 Pending-task-def-bia-alb:2
              - 7777165179419921139|View tasks-Source-0 Requested-0 Running-0 Pending-task-def-bia-alb:2
            - Obs ( Depois de disparar)
#### Passo 5 - Problema(Deploy precisa de um script na nossa maquina para acontecer)
- Solução(Pipeline CI/CD)
  - ao realizar um push no branch main vai ser disparado um pipeline (fluxo ci/cd)
    - um hook no github vai ser dispado ao receber o push no branch main
  - vai ser configurado no bia-dev
- Configurar o Code Pipeline com a conta e o repositorio
  - ir em create new pipeline
  - escolher build custom pipeline
  - name: bia
  - execution: superseaded (para o atual e manda outro), paralled caso queira testar integraçao continua
  - next  
  - source provider: github
  - conectar ao git hub
  - app installation: escolher se tiver ou instalar qdo for nova e escolher o repositorio e depois "conect"
  - voltando escolher o repositorio e o branch
  - no build: escoloher "Other build providers" escolher "AWS Code build"
  - projetc name: criar um novo project com o nome: "bia-build" e deixar default as opções do projeto
  - expandir "Additional configuration" e marcar "Enable this flag if you want to build Docker ...."
  - adicionar o "buldspec", escolher "user a buildspec file" 
  - dar skip na fase de test
  - desmarcar "configure automatic"
  - informar no Add Deploy Stage "Amazon ECS"
  - informar o cluster name: "cluster-bia-alb"
  - informar o service: "service-bia-alb"
  - no image definition: deixar a convesão (nao mexer)
  - create pipeline
- Ajustar o Build Project
  - selecionar o bio-build
  - ver o build logs
  - entrar no ECR -> latest e copiar a URI
  - entrar na instancia do bia-dev e 
    - nano buildspec.yml para alterar a URI
    - git add buildspec.yml
    - git commit -m "correção do usuario de buildspec"
- Criar o Code Pipeline
  - criar o arquivo buildspec.yml
    - ajustar o id da conta dentro do buildspec.yml
  - criar o bia-pipeline no Code Pipeline
  - criar o Code Build
  - Configurar Deployment
  - ajustar o usuario (erro no build)
  - ajustar autorização da role (erro no build)
    - ir no IAM e achar a role "codebuild-bia-build-service-role" que foi criada ao criar o "criar o build pipeline"
    - qual permissao faltou? autenticar no ECR
      - add role "..containerRegistryPowerUser"
      - volta ao Pipe Line -> clica em Retry
      - depois que o build passou ir para o ECS
      - abrir o servico e ver se as tasks rodando

#### Passo 6 - Dominio com https
- configurar ALB e Listener
- configurando o Route 53
- Fazerndo deploy com ajustes no Dockerfile (env do vite)
- Primeira ação
  - no ACM verificar se o certificado está como emitido "issued"
  - no EC2 ir em "Load Balancers" -> "bia-alb"
    - achar no menu horizontal "Listeners e rules"
      - temos listener configurado para a porta 80, vamos configurar para Https 443
      - add listener e selecionar Https 443
      - qdo bater na 443 vo mandar para o target group 
        - selecionar o "tg-bia"
      - dai selecionar o certificado  (from ACM), no caso o que foi configurado no ACM vai aparecer
- Segunda ação
  - ir no Route 53 se selecionar 2 entradas
    - selecioar DNS -> Hosted zones -> selecionar o devblue.com.br e "create record"    
    - clicar em "create record" -> ipv4 - Qual é o dominio/subdominio que vou ultilizar? "formacao-aws.devblue.com.br"
      - record name: formacao-aws
      - record type: A - Routes ... (ipv4)
      - ativar/marcar "Alias"
      - selecionar "Alias to Application and Classic Load Balancer"
      - selecionar regiao "Us East (N. Virginia)"
      - selecionar o load balancer "dualstack.bia-alb-xxxxx.us.east-1.elb.amazonaws.com"
      - create record (finalizar)
    - repetir e clicar em "create record" para criar para o ipv6
      - record type: AAA - Routes ... (ipv6)
    - fazer o teste se está funcinando acessando "formacao-aws.devblue.com.br"
    - falta apontar a api para o novo dns (endereço)
- Terceira ação - como fazer a troca do endereço da api para apontar para o dominio e não mais para o ip?
  - entrar no EC2 e conectar no bia-dev
  - trocar o ip para o enderço no Dockerfile dentro do 
  - nano Dockerfile
  - git pull --no-rebase
  - git add Dockefile
  - git commit -m "troca do ip para endereço na api"
  - git push origin main

#### Passo 7 - Criar infra usando liguagem natural
- arquitetura que vamos montar
- estou 2 instancias com 1vcpu e 500mb sem uso ( pois estou usando estrategia é "AZ Balance Spreed")
  - zona a (2vcpu + 900mb) 
    - ao colocar 1 instancia (1vcpu + 400mb) 
    - fica livre 1vcpu + 500mb
  - zona b (2vcpu + 900mb)
    - ao colocar 1 instancia (1vcpu + 400mb) 
    - fica livre 1vcpu + 500mb
- E se eu criar um novo service? Para aproveitar o meu cluster?
  - para ver esse cenario antes de criar, vou  em ECS->cluster->cluster-bia-alb->infrastructure->container instances (2)
  - então podemos criar um novo service e aproveitar o loadbalancer
  - já temos o tb-bia ( Mas o que o tg-bia faz? qual sua função?)
- Criar um novo targetGroup "tg-bia-dev" para que nosso listener (não sei quem é o listener rsrs), passe a mandar ou para o tg-bia (instancias antigas que já estavam configuradas) ou para o novo tg-bia-dev que tambem vai gerenciar 2 novas instancias com um novo task-definition esclusivo para atender essas novas instancias  
  - primeiro vamos ajustar o listener para verificar qual o endereço (novo formacao-dev.devblue.com.br) e o (antigo formacao-aws.devblue.com.br)
  - listener vai tomar a decisao de qual targetgroup vai receber a requisição, ou seja, o listener entrega para o tg especifico
  - caso o novo tg-bia-dev receba a requisicao ele encaminha para um novo service "service-dev-alb" ( que vai ser adidionado no cluster atual "cluster-bia-alb" dentro do ECS)
    - o novo service vai ter sua propria task definition (nova) para que vai criar as novas tasks (instancias e coloca-las dentro das instancias existentes porem consumindo recursos que ainda estão disponiveis/não utilizados)
    - o que tem dentro de um task definition (variaveis de ambiente, img uri, memoria, cpu)
  - como criar isso na mão?
    - ir no tg e criar o novo tg
    - ir no listener e criar uma regra para o novo endereço (host header para fazer o desvio do trafego)
    - ir no service e colocar para apontar para um nova revision e executar essa configuração
    - mas faremos isso tudo com kiro-cli
- Usando o kiro-cli para criar todos os passos
  - lembrar:
    - tg deve ser criado com attribute deregistration delay (draining interval de 30s), para que isso? resp: para o deploy não demorar horrores
  - prompt:
    - preciso de sua ajuda para criação de uma infraestrutura na aws. Nesse Monmento eu tenho um load balancer "bia-alb", um listener na porta 443 e quero criar uma role para quando a request vier de formacao-dev.devblue.com.br (host header) envie para o tg-bia-dev ( que deve ser criado com deregistration delay de 30s). Quero tambem que voce crie um service no meu cluster-bia-alb chamado service-bia-alb-dev. Esse service deve apontar para a mesma task-definition do service-bia-alb e ter as mesmas configurações exceto o target group que deve ser o que estamos criando "tg-bia-dev". Me descreva antes de executar se compreendeu todos os passos.
    - Passos a serem executados:
      1. Criar Target Group tg-bia-dev
        - Deregistration delay: 30 segundos
        - Configurações compatíveis com ECS (provavelmente porta 8080 baseado no padrão do projeto)

      2. Criar Listener Rule no listener 443 do bia-alb
        - Condição: Host header = formacao-dev.devblue.com.br
        - Ação: Forward para tg-bia-dev

      3. Obter configurações do service existente service-bia-alb
        - Identificar a task definition utilizada
        - Capturar configurações relevantes (desired count, launch type, network config, etc)

      4. Criar novo service service-bia-alb-dev
        - Cluster: cluster-bia-alb
        - Mesma task definition do service-bia-alb
        - Mesmas configurações do service original
        - Target group: tg-bia-dev (diferença principal)
  - tive problema par subir as tasks do novo service, pois o tg-bia e o service-bia-alb estava usando porta fixa 80 e deveria estar usando portas dinamicas (acabei configurando errado)
    - Encontrei o problema! A task definition tem hostPort: 80 fixo. Para usar portas dinâmicas, preciso criar uma nova task definition com hostPort: 0 (ou sem especificar hostPort):
      - parece que o tg fica com a porta 80 mesmo ???,  e só o task definition é que fica com portas dinamicas ????
    - o que é importante é o task definition deve ser criado para portas dinamicas, pois ele vai ser usado novamente para criar os novos serviços
    - Resultados:
      - Target Group tg-bia-new:
        - Configurado com portas dinâmicas ✅
        - 2 targets registrados com porta 32768 (porta alta/aleatória) ✅
        - Ambos targets healthy ✅
        - Deregistration delay: 30 segundos ✅

      - Service service-bia-alb:
        - 2 tasks rodando ✅
        - Task definition: task-def-bia-alb:8 (com hostPort: 0) ✅
        - Deployment completado ✅
        - Status: ACTIVE e steady state ✅

      - Portas Dinâmicas Funcionando:
        - As instâncias estão registradas com porta 32768 (porta alta)
        - ECS está gerenciando automaticamente as portas
        - Múltiplas tasks podem rodar na mesma instância agora
            - pedi para o kiro arrumar para mim, mas ele disse que seria preciso apagar e recriar tudo tg-bia e service-bia-alb, para depois criar os novos tg-bia-dev e service-bia-alb-dev

      - **Portas Dinâmicas Funcionando:**
        - **tg-bia-new:** Porta 32768
        - **tg-bia-dev:** Porta 32769
        - Múltiplas tasks podem rodar nas mesmas instâncias
        - ECS gerencia automaticamente as portas alta


- Faltar criar no Route 53 a entrada para o novo endereço "formacao-dev.devblue.com.br"
- Outro problema "formacao-dev" está usando a mesma task definition
  - devemos ir no ECR e usar outra IMG
  - devemos trocar no Dockerfile da IMG para ele apontar para a nova url
- Duvida, se eu alterar o codigo no brach main e fazer um push as 2 URLs vão ficar atualizadas com o novo codigo?
  - não, pois o pipeline configurado para um service e o service configurado é o service-bia-alb, ou seja, o outro service "...dev" mesmo usando a mesma task definition não está configurado no pipeline e não vai ser disparada a alteração feito na IMG ( ECR ).

#### Passo 8 - Parando os recursos para não gerar custos
  - DB (Aurora e RDS), marcar e tem conhecimento e não marcar snapshot  
  - Instancias, para primeiro a bia-dev  
  - ECS
    - entrar dentro de cada service (update) e em "Desired tasks" modificar task de 2 para 0, depois update
    - EC2 -> load balance
      - deletar o bia-alb (Proceeding with this action deletes the load balancer and its listeners)
      - os target groups vao permanecer e podem ser reutilizados
    - EC2 -> auto Scaling groups
      - ir em "action" e colocar em "Desired capacity, Min desired capacity, Max desired capacity" os valores zero na sequencia "0,0,0"
      - com isso ele vai deletar as instancias automaticamente (Terminated)
    - ECR - tem pouco custo não precisa mexer por enquanto

## Dia 2  - Tarde

- Teste pela rota de backend (/api/versao)

## Recursos criados que tenho que deletar na zona para trabalho

1. uma instancia EC2
2. security groups (SGs)
  bia-dev
   bia-web
   bia-db
3. um RDS database


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

