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
$ msca-reqcert.sh -s root-ca.contoso.ad -u foo@bar -p 1234567 -c root-ca.contoso.ad.cer

#Retrieve CA chain file
$ msca-reqcert.sh -s root-ca.contoso.ad -u foo@bar -p 1234567 -i sub-ca-bundle.contoso.ad.cer

#Request a new certificate from a CSR file
$ msca-reqcert.sh -s root-ca.contoso.ad -u foo@bar -p 1234567 -t WebServer -r request.csr

#Request a new certificate from scratch
$ msca-reqcert.sh -s root-ca.contoso.ad -u foo@bar -p 1234567 -t WebServer -k server.key -n server.contoso.ad
```