# Microsoft Certificate Authority Request tool

## To Setup

Download msca-reqcert.sh to your /bin environment.

```bash
sudo curl https://raw.githubusercontent.com/davibaldin/msca-reqcert/main/msca-reqcert.sh -o /bin/msca-reqcert.sh
sudo chmod +x /bin/msca-reqcert.sh
```

## Usage

```bash
msca-reqcert.sh -h
```

## Examples

```bash
#Retrieve CA file:
$ msca-reqcert.sh -s ca.contoso.ad -u foo@bar -p 1234567 -c root-ca.contoso.ad.cer

#Retrieve CA chain file
$ msca-reqcert.sh -s ca.contoso.ad -u foo@bar -p 1234567 -i sub-ca-bundle.contoso.ad.cer

#Request a new certificate from a CSR file
$ msca-reqcert.sh -s ca.contoso.ad -u foo@bar -p 1234567 -t WebServer -r request.csr

#Request a new certificate from scratch to 
$ msca-reqcert.sh -s ca.contoso.ad -u "someuser@somedomain" -d "/C=BR/ST=Sao Paulo/L=Araraquara/O=ANEXT" -n app.anext.com.br -k app.anext.com.br.pem
```

## Next steps

### Add corporate CA to trusted (Red Hat Like)

Add your root CA and all yours sub-CAs [https://access.redhat.com/solutions/3220561](Read more)

```bash
msca-reqcert.sh -s ca.contoso.ad -u foo@bar -p 1234567 -c /etc/pki/ca-trust/source/anchors/ca-root.contoso.ad.pem
msca-reqcert.sh -s ca-sub.contoso.ad -u foo@bar -p 1234567 -c /etc/pki/ca-trust/source/anchors/ca-sub.contoso.ad.pem
update-ca-trust extract
```

### Concatenate files to NGINX configuration

Request your CA chain (if issued from a sub-CA) and concatenated it to a single file for NGINX.

```bash
msca-reqcert.sh -s ca.contoso.ad -u foo@bar -p 1234567 -i /etc/ssl/ca.contoso.ad.pem
msca-reqcert.sh -s ca.contoso.ad -u foo@mar -d "/C=BR/ST=Sao Paulo/L=Araraquara/O=ANEXT" -n app.anext.com.br -k /etc/ssl/app.anext.com.br.key -w /etc/ssl/app.anext.com.br.pem
cat /etc/ssl/app.anext.com.br.pem /etc/ssl/ca.contoso.ad.pem > /etc/ssl/app.anext.com.br.bundle
```

Configure NGINX (example)

```
server {
  listen 443;
  ssl on;
  ssl_certificate /etc/ssl/app.anext.com.br.bundle;
  ssl_certificate_key /etc/ssl/app.anext.com.br.key;
```
