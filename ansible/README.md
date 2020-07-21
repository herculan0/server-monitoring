Here we have 4 roles for Ansible:
docker, grafana, jenkins and nginx
Install any of these using --tags in ansible-playbook like:
`ansible-playbook -v playbook.yml -e target=ec2 --tags "jenkins"`
And with the playbook.yml file you can install all of them (need to specify hosts in playbook.yml file)
`ansible-playbook -v playbook.yml -e target=ec2`
