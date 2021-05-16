#!/bin/bash

# /*
#  * Licensed to the Apache Software Foundation (ASF) under one or more
#  * contributor license agreements.  See the NOTICE file distributed with
#  * this work for additional information regarding copyright ownership.
#  * The ASF licenses this file to You under the Apache License, Version 2.0
#  * (the "License"); you may not use this file except in compliance with
#  * the License.  You may obtain a copy of the License at
#  *
#  *      http://www.apache.org/licenses/LICENSE-2.0
#  *
#  * Unless required by applicable law or agreed to in writing, software
#  * distributed under the License is distributed on an "AS IS" BASIS,
#  * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  * See the License for the specific language governing permissions and
#  * limitations under the License.
#  */

function show_usage()
{
    echo "Microsoft CA issuer client."
    echo "A little help to issue certificates to Linux services based on a Microsoft Network."
    echo ""
    echo "Options:"
    echo " -s ca-server.fqdn        Set server to requests certificates from."
    echo ""
    echo " -u user@domain           Login to authenticated against Active Directory."
    echo ""
    echo " -p pass              pass (insecure). pass will be prompted if missing."
    echo ""
    echo " -c path/to/ca.cer        Retreive CA File."
    echo ""
    echo " -i path/to/ca.cer        Retreive CA chain File."
    echo ""
    echo " -t TemplateName          Microsoft CA Template to be used. Default is WebServer."
    echo ""
    echo " -k path/to/private.key   Path to private key. If private key doesn't exist, a new 2048 key"
    echo "                          with 2048 bits and no passphrase will be generated."
    echo ""
    echo " -r path/to/request.csr   Path to certificate request file. If file doesnt exist an error"
    echo "                          will be thrown. -key will be ignored if csr file is provided."
    echo ""
    echo " -d /C=/ST=/L=/O=         Path of requested subject name to append before CN. If not provided,"
    echo "                          the default will be used: /C=CC/ST=State/L=Location/O=Corporation"
    echo "                          Ignored if csr file is provided."
    echo ""
    echo " -n Server FQDN (CN)      Server full qualified domain name. Ignored if csr file is provided."
    echo "                          If omitted, current hostname will be used."
    echo ""
    echo " -a alternate1,alternate2 SAN Names coma separeated if required."
    echo ""
    echo " -m E-mail address        Email adddress to be appended Server full qualified domain name."
    echo "                          If not provided hostmaster@fqdn will be used."
    echo "                          Ignored if csr file is provided."
    echo ""
    echo " -w path                  Path to certificate file. If omitted, file will be create at current"
    echo "                          directory as FQDN.cer filename."
    echo ""
    echo " -h                       This message."
    echo ""
    echo "Examples:"
    echo "  Retrieve CA file:"
    echo "  $0 -s root-ca.contoso.ad -u foo@bar -p 1234567 -c root-ca.contoso.ad.cer"
    echo ""
    echo "  Retrieve CA chain file:"
    echo "  $0 -s root-ca.contoso.ad -u foo@bar -p 1234567 -i sub-ca-bundle.contoso.ad.cer"
    echo ""
    echo "  Request a new certificate from a CSR file"
    echo "  $0 -s root-ca.contoso.ad -u foo@bar -p 1234567 -t WebServer -r request.csr"
    echo ""
    echo "  Request a new certificate from scratch"
    echo "  $0 -s root-ca.contoso.ad -u foo@bar -p 1234567 -t WebServer -k server.key -n server.contoso.ad -d /C=BR/ST=Sao Paulo/L=Campinas/O=Infolayer"
    echo ""

    exit 0
}

while getopts s:u:p:c:i:t:k:r:d:n:m:a:w:h flag
do
    case "${flag}" in
        s) server=${OPTARG};;
        u) user=${OPTARG};;
        p) pass=${OPTARG};;
        c) getca=${OPTARG};;
        i) getcachain=${OPTARG};;
        t) tpl=${OPTARG};;
        k) key=${OPTARG};;
        r) csr=${OPTARG};;
        d) subj=${OPTARG};;
        n) fqdn=${OPTARG};;
        m) email=${OPTARG};;
        a) san=${OPTARG};;
        w) writeto=${OPTARG};;
        h) show_usage;;
    esac
done

#echo -e "DEBUG 1 \n server = ${server}\n user = ${user}\n pass = ${pass}\n getca = ${getca}\n getcachain = ${getcachain}\n tpl = ${tpl}\n key = ${key}\n subj = ${subj}\n csr = ${csr}\n fqdn = ${fqdn}\n email = ${email}\n"
# Thanks to: https://stackoverflow.com/questions/31283476/submitting-base64-csr-to-a-microsoft-ca-via-curl


SANATTRS=""
CURL_HTTP1=""

#Check if running is macOS
UNAME=`uname`
if [ "${UNAME}" == "Darwin" ]
then
    CURL_HTTP1="--http1.1"
fi

function gen_san_file() {
    cat > /tmp/${fqdn}.san <<EOF
[ req ]
default_bits       = 2048
distinguished_name = req_distinguished_name
req_extensions     = req_ext
[ req_distinguished_name ]
countryName                = Country Name (2 letter code)
stateOrProvinceName        = State or Province Name (full name)
localityName               = Locality Name (eg, city)
organizationName           = Organization Name (eg, company)
commonName                 = Common Name (e.g. server FQDN or YOUR name)
[ req_ext ]
subjectAltName = @alt_names
[alt_names]
EOF

SANID=1
echo "DNS.${SANID} = ${fqdn}" >> /tmp/${fqdn}.san
for name in ${SANATTRS}
do
    ((SANID=SANID+1))
    echo "DNS.${SANID} = ${name}" >> /tmp/${fqdn}.san
done

}

function get_ca_cert_chain() {
    curl ${CURL_HTTP1} -k -s -u "${user}":${pass} --ntlm -XGET \
        "https://${server}/certsrv/certnew.p7b?ReqID=CACert&Renewal=0&Enc=b64" \
        -o /tmp/getcachain.p7b
    openssl pkcs7 -print_certs -in /tmp/getcachain.p7b -outform PEM > ${getcachain}
    return $?
}

function get_ca_cert() {
    curl ${CURL_HTTP1} -k -s -u "${user}":${pass} --ntlm -XGET \
        "https://${server}/certsrv/certnew.cer?ReqID=CACert&Renewal=0&Enc=b64" \
        -o ${getca}
    return $?
}

function gen_priv_key() {
    openssl genrsa -out ${key} 2048
}

function gen_csr() {
    gen_san_file
    openssl req -new -key ${key} -out /tmp/${fqdn}.csr -subj "${subj}/CN=${fqdn}/emailAddress=${email}" -config /tmp/${fqdn}.san
    return $?
}

function req_certificate {
    CERT=`cat /tmp/${fqdn}.csr | tr -d '\n\r'`
    CERT=`echo ${CERT} | sed 's/+/%2B/g'`
    CERT=`echo ${CERT} | tr -s ' ' '+'`
    CERTATTRIB="CertificateTemplate:${tpl}"
    DATA="Mode=newreq&CertRequest=${CERT}&CertAttrib=${CERTATTRIB}&TargetStoreFlags=0&SaveCert=yes&ThumbPrint="

    curl ${CURL_HTTP1} -k -s -u "${user}":${pass} --ntlm -XGET \
    "https://${server}/certsrv/certfnsh.asp" \
    --data "${DATA}" -o /tmp/${fqdn}.res

    if [ ! -f "/tmp/${fqdn}.res" ]
    then
        echo "Certificate request failed. No response from CA server."
        exit 2
    fi

    REQID=`cat /tmp/${fqdn}.res | grep ReqID= | cut -d= -f 4 | cut -d\& -f1 | head -1`

    curl ${CURL_HTTP1} -k -s -u "${user}":${pass} --ntlm -XGET \
        "https://${server}/certsrv/certnew.cer?ReqID=${REQID}&Enc=b64" \
        -o ${writeto}

     echo "Certificate issued. Certificate ID is $REQID, File is: ${writeto}"
     rm -f /tmp/${fqdn}.res
     rm -f /tmp/${fqdn}.san
}

if [ -z "${server}" ]
then
    echo ""
    echo "-s server must be supplied. Use -h for usage."
    exit 1
fi

if [ -z "${user}" ]
then
    echo ""
    echo "-u user must be supplied. Use -h for usage."
    exit 1
fi

if [ -z "${pass}" ]
then
    echo -e "Password: \c"
    read -s pass
fi

if [ -z "${fqdn}" ]
then
    fqdn=`hostname -f`
fi

if [ ! -z "${getca}" ]
then
    
    get_ca_cert
    if [ "$?" -eq "0" ]
    then
        check=`head -n 1 ${getca} | cut -d- -f6`
        if [ "$check" == "BEGIN CERTIFICATE" ]
        then
            echo "Downloaded CA file to ${getca}."
            exit 0
        fi
    fi
    echo "Erro while downloading CA file. Check connection or permission."
    exit 1
fi

if [ ! -z "${getcachain}" ]
then
    get_ca_cert_chain
    if [ "$?" -eq "0" ]
    then
        check=`cat ${getcachain} | grep 'BEGIN CERTIFICATE' | cut -d- -f6`
        if [ "$check" == "BEGIN CERTIFICATE" ]
        then
            echo "Downloaded CA chain file to ${getcachain}."
            exit 0
        fi
    fi
    echo "Erro while downloading CA chain file. Check connection or permission."
    exit 1
fi

if [ ! -z "${key}" ]
then
    if [ ! -f "${key}" ]
    then
        echo "Key file doesn't exist. Creating a new private key."
        gen_priv_key ${key}
    fi
else
    echo "-k path/to/key.pem must be supplied. Use -h for usage."
    exit 1
fi

if [ -z "${email}" ]
then
    email="hostmaster@${fqdn}"
fi

if [ -z "${subj}" ]
then
    subj="/C=CC/ST=State/L=Location/O=Corporation"
fi

if [ -z "${tpl}" ]
then
    tpl="WebServer"
fi

if [ ! -z "${san}" ]
then
    for str in ${san//,/ }
    do 
        SANATTRS="${SANATTRS} ${str}"
    done
    SANATTRS="${SANATTRS:1}"
fi

if [ ! -z "${csr}" ]
then
    if [ ! -f "${csr}" ]
    then
        echo "CSR file doesn't exist. If you want to create a new CSR and certificate, please inform flags -k, -j and -n instead."
        exit 3
    fi
else
    gen_csr
    csr=/tmp/${fqdn}.csr
    echo "Created a new CSR file at ${csr}."
fi

if [ -z "${writeto}" ]
then
    dir=`pwd`
    writeto="${dir}/${fqdn}.cer"
else
    if [ -d "${writeto}" ]
    then
        echo "Write to cannot be directory."
        exit 4
    fi
fi

#echo "DEBUG 2\n server = ${server}\n user = ${user}\n pass = ${pass}\n getca = ${getca}\n getcachain = ${getcachain}\n tpl = ${tpl}\n key = ${key}\n subj = ${subj}\n csr = ${csr}\n fqdn = ${fqdn}\n email = ${email}\n"

echo "Requesting certificate to ${server} for ${fqdn}, template is: ${tpl}"
req_certificate