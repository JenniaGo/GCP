#
#
#
# Prepare the lab vars
gcloud auth list

region=us-east1
zone=us-east1-b

# Dev network
vpc_dev=griffin-dev-vpc
sn_dev_wp=griffin-dev-wp
sn_dev_wp_cidr=192.168.16.0/20
sn_dev_mgmt=griffin-dev-mgmt
sn_dev_mgmt_cidr=192.168.32.0/20

# Prod network
vpc_prod=griffin-prod-vpc
sn_prod_wp=griffin-prod-wp
sn_prod_wp_cidr=192.168.48.0/20
sn_prod_mgmt=griffin-prod-mgmt
sn_prod_mgmt_cidr=192.168.64.0/20

# default machine size
mach=e2-medium

# Dev GKE cluster name
gke=griffin-dev

# The user we need to give access to.
user2=supply-your-user-email

gcloud config set compute/region $region
gcloud config set compute/zone $zone

## Create networks
# First, the Dev network
gcloud compute networks create $vpc_dev --subnet-mode=custom --mtu=1460 --bgp-routing-mode=regional
gcloud compute networks subnets create $sn_dev_wp \
  --range=$sn_dev_wp_cidr --stack-type=IPV4_ONLY \
  --network=$vpc_dev --region=$region
gcloud compute networks subnets create $sn_dev_mgmt \
  --range=$sn_dev_mgmt_cidr --stack-type=IPV4_ONLY \
  --network=$vpc_dev --region=$region

# Then the Prod network
gcloud compute networks create $vpc_prod --subnet-mode=custom --mtu=1460 --bgp-routing-mode=regional
gcloud compute networks subnets create $sn_prod_wp \
  --range=$sn_prod_wp_cidr --stack-type=IPV4_ONLY \
  --network=$vpc_prod --region=$region
gcloud compute networks subnets create $sn_prod_mgmt \
  --range=$sn_prod_mgmt_cidr --stack-type=IPV4_ONLY \
  --network=$vpc_prod --region=$region

# And firewall rules, so we can connect to our bastion
gcloud compute firewall-rules create fw-ssh-dev --network $vpc_dev --allow tcp:22,tcp:3389,icmp
gcloud compute firewall-rules create fw-ssh-prod --network $vpc_prod --allow tcp:22,tcp:3389,icmp

#
# Create bastion
gcloud compute instances create bastion \
  --project=$prj \
  --zone=$zone \
  --machine-type=$mach \
  --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=$sn_dev_mgmt \
  --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=$sn_prod_mgmt \
  --metadata=enable-oslogin=true \
  --scopes=https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/trace.append

# Setup Cloud SQl
gcloud sql instances create griffin-dev-db \
  --database-version=MYSQL_8_0_31 \
  --tier=db-n1-standard-1 \
  --region=$region \
  --edition=enterprise \
  --root-password=<whatever!>

# Now connect to it (from Cloud Shell)
gcloud sql connect griffin-dev-db --user=root --quiet
