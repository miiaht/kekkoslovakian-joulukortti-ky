# Kekkoslovakian Joulukortti Ky -migration

## IAP TCP forwarding with Bastion
- encrypted tunnel to forward SSH traffic to VM instance

# 1. To use instance scheduling
- make sure @compute-system.iam.gserviceaccount has compute intance admin role

# 2. To run
- terraform apply

## 3. Once apply is complete, connect to Bastion instance with SSH. To connect to database first connect to henkilostohallinta or reskontra instance:

- gcloud compute ssh henkilostohallinta --internal-ip

# or 

- gcloud compute ssh reskontra --internal-ip 


# 4. To connect to henkilosto or reskontra database:

- psql -h sql-instance-private-ip -U henkilosto 
- psql -h sql-instance-private-ip -U reskontra

## 5. To connect to instance using Cloud SDK
- Make sure Cloud SDK is confgured on your machine

# 6. To configure the project and details use command
- gcloud init

# 7. Check configuration
- gcloud config list

# 8. To start using IAP Bastion host
- gcloud compute ssh --tunnel-through-iap --zone=<zone_name> <bastion_instance_name>

# 9. Connect to server behind Bastion host
- Use commands in step 3.
