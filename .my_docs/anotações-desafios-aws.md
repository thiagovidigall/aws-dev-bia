# Depois de fazer upgrade do plano free tier
- ficar de olho em "Estimate future costs" - "AWS Pricing calculator"
- ficar de olho em "Optimize your costs" - "Cost Optimization Hub"


# O QUE TEM QUER SER APAGADO PARA NAO GERAR CUSTOS
1. EC2 e os SGs (security groups) criados para ele
2. RDS apagar o banco que foi criado
3. LAMBDA (URL E LAMBDA)

## 1. primeiro criar uma EC2
- criei uma instance ec2 com nome "test instance"  (APAGAR-ok)
- criei um key pair "keypair-test-instance"  (APAGAR ? ao apagar a instancia)
- criei um EBS volume sem encrypted volume  (APAGAR ? ao apagar a instancia) 
- usei vpc default "vpc-0635dbbc34af833a7" e subnet "default
- criei um sg "sg-02906463ce70f3ba2 (launch-wizard-1)" para essa instancia (APAGAR-ok)
- o volume EBS e apagado junto com  a instancia 

## 2. segundo criar um RDS
- criei e coloquei um pass: Banco12#  (APAGAR-ok)
- ao apagar, não esquecer de desmarcar o "create final snapshot"
- ao apagar, não esquecer de desmarcar o "retain automated backups"

## 3. terceito criar um Lambdar Function
- criei com nome "http-function-url-tutorial" (APAGAR)
- deletar "Function URL"  (APAGAR-ok)
- deletar "Fucntion"  (APAGAR-ok)
- links:
 - [link1](https://us-east-1.console.aws.amazon.com/lambda/home?region=us-east-1#/begin)
 - [link2](https://docs.aws.amazon.com/lambda/latest/dg/getting-started.html)
- usei esse codigo que veio de forma default:

``` js
import * as fs from 'node:fs';

const html = fs.readFileSync('index.html', { encoding: 'utf8' });

/**
 * Returns an HTML page containing an interactive Web-based tutorial.
 * Visit the function URL to see it and learn how to build with lambda.
 */
export const handler = async () => {
    const response = {
        statusCode: 200,
        headers: {
            'Content-Type': 'text/html',
        },
        body: html,
    };
    return response;
};
```


