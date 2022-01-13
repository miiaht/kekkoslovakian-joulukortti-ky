# Kekkoslovakian Joulukortti Ky -migration

## IAP TCP forwarding with Bastion
- encrypted tunnel to forward SSH traffic to VM instance

# To use instance scheduling make sure @compute-system.iam.gserviceaccount has compute intance admin role

# To run
- terraform apply

## Once apply is complete, connect to Bastion instance with SSH. To connect to database first connect to henkilostohallinta or reskontra instance:

- gcloud compute ssh henkilostohallinta --internal-ip

# or 

- gcloud compute ssh reskontra --internal-ip 


# To connect to henkilosto or reskontra database:

- psql -h sql-instance-private-ip -U henkilosto 
- psql -h sql-instance-private-ip -U reskontra
