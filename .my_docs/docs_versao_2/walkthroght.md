### criado na aws
1. billing and cost management ->
- create budget, type month.., amount 5 dollars
2. IAM 
- create role , service aws, use case EC2, e adicionar permission "...ssmmanagedin..."
3. EC2
- create security groups, create, name "bia-dev", vpc padrão, rule inbound (custom tcp, 3001, ipv4, 0.0.0.0/0)
- create instance groups, create, name "bia-dev", vpc padrão, rule inbound (custom tcp, 3001, ipv4, 0.0.0.0/0)
4. 


### ajustes e configurações
1. na engrenagem trocar tema e idioma
2. aws cloudshell vai rodar scripts para subir recursos
  - vai ser usanda para subir:
    - validar recursos atraves do script de validação
    - uma instancia de EC2
    - um securite group "bia-dev"
    - uma role no IAM para permitir o acesso da instancia por SSM
