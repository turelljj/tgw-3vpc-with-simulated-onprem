# output "test-helper-command-1" {
#     value = ["${module.tester-vpc-10.private_ip}"]
# }
# # output "test-helper-command-2" {
# #     value = "ssh centos@${module.on-prem.on_prem_public_ip} ping ${module.tester-vpc-20.private_ip[0]} -I 192.168.1.10"
# # }
# # output "test-helper-command-3" {
# #     value = "ssh centos@${module.on-prem.on_prem_public_ip} ping ${module.tester-vpc-20.private_ip[0]} -I 192.168.1.10"
# # }