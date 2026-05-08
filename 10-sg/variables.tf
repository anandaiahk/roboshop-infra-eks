variable "project" {
    default = "roboshop"
}
variable "environment" {
    default = "dev"
}

variable "sg_names" {
    type = list 
    default = [
        # database 
        "mongodb","redis","mysql","rabbitmq",
        # backend
        #"catalogue","user","cart","shipping","payment",
        # backend-alb
        #"backend_alb",
        # frontend
        #"frontend",
        # frontend-alb
        "ingress_alb",
        "bastion",
        "openvpn",
        "eks_node",
        "eks_control_plane"
    
    ]
}