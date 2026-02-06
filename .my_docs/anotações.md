# Passo a Passo AWS

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



      








# Recursos de uma zona para trabalho

### Sequencia pra a de configuração de recursos

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

