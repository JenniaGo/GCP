# Implement Load Balancing on Compute Engine: Challenge Lab
# I defined variables to make the commands easier: (please, review data in your Lab assigned!)
 
export INSTANCE_NAME=nucleus-jumphost-839 
export ZONE=us-west3-b
export REGION=us-west3
export FIREWALL_NAME=grant-tcp-rule-902
export NETWORK=default
 
# I used the default network because it is the only one I had created in my project
 
# Task 1. Create a project jumpiest instance

gcloud compute instances create $INSTANCE_NAME \
    --network $NETWORK \
    --zone $ZONE \
    --machine-type e2-micro \
    --image-family debian-11 \
    --image-project debian-cloud
 
# Task 2. Set up an HTTP load balancer

cat << EOF > startup.sh
#! /bin/bash
apt-get update
apt-get install -y nginx
service nginx start
sed -i -- 's/nginx/Google Cloud Platform - '"\$HOSTNAME"'/' /var/www/html/index.nginx-debian.html
EOF

gcloud compute instance-templates create web-server-template \
    --metadata-from-file startup-script=startup.sh \
    --network $NETWORK \
    --machine-type e2-medium \
    --region $REGION

gcloud compute target-pools create nginx-pool --region=$REGION

gcloud compute instance-groups managed create web-server-group \
    --base-instance-name web-server \
    --size 2 \
    --template web-server-template \
    --region $REGION

gcloud compute firewall-rules create $FIREWALL_NAME \
    --allow tcp:80 \
    --network $NETWORK

gcloud compute http-health-checks create http-basic-check

gcloud compute instance-groups managed \
    set-named-ports web-server-group \
    --named-ports http:80 \
    --region $REGION

gcloud compute backend-services create web-server-backend \
    --protocol HTTP \
    --http-health-checks http-basic-check \
    --global

gcloud compute backend-services add-backend web-server-backend \
    --instance-group web-server-group \
    --instance-group-region $REGION \
    --global

gcloud compute url-maps create web-server-map \
    --default-service web-server-backend

gcloud compute target-http-proxies create http-lb-proxy \
    --url-map web-server-map

gcloud compute forwarding-rules create $FIREWALL_NAME \
    --global \
    --target-http-proxy http-lb-proxy \
    --ports 80
