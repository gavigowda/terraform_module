# Terraform-ops
To create a ECS Cluster using Terraform modules.

This repo contains a Module for creating a ECS cluster in AWS using the terraform.

> What is ECS and how it works in AWS?
>> Amazon Elastic Container Service (ECS) is a highly scalable, high performance container management service that supports Docker containers and allows you to easily run applications on a managed cluster of Amazon Elastic Compute Cloud (Amazon EC2) instances.

### About
Terraform module to run ECS cluster, with ASG + Launch Template + Scaling policies via capacity provider

### Features
* **Container Management**: ECS enables you to run and manage Docker containers without the need to install and operate the underlying container orchestration infrastructure. It provides a highly scalable and reliable platform for containerized applications.

* **Cluster Management**: ECS allows you to create and manage logical groupings of container instances known as clusters. A cluster can span multiple Availability Zones and can be dynamically scaled to accommodate your application's requirements.

* **Task Definitions**: ECS uses task definitions to define the containers that make up your application. A task definition includes information such as the Docker image, resource requirements, networking settings, and container dependencies. It provides a declarative way to define your application's architecture.

* **Task Scheduling**: ECS offers flexible scheduling options to run tasks across your cluster. It supports both EC2 launch type and Fargate launch type. With EC2 launch type, you can leverage your existing EC2 instances, while Fargate launch type allows you to run containers without managing the underlying infrastructure.

* **Service Auto Scaling**: ECS provides built-in support for scaling your services based on metrics such as CPU utilization, memory utilization, or custom CloudWatch metrics. You can define scaling policies to automatically adjust the number of tasks in your service based on these metrics.


This guide explains how to create an ECS cluster in AWS using Terraform. The cluster will include necessary resources such as VPC, subnets, security groups, IAM roles, and ECS service.

### **Prerequisites**
> Before you begin, make sure you have the following prerequisites:

* AWS account credentials with appropriate permissions to create resources.
* Terraform installed on your local machine. You can download it from the official Terraform website: Terraform Downloads.
* Basic knowledge of AWS services, ECS, and Terraform.

## Steps
Follow the steps below to create an ECS cluster in AWS using Terraform:

* **Step 1**: **Clone the Repository**
>> Clone the Terraform configuration repository to your local machine using the following command:
>>> $ git clone <repository_url>

Navigate to the repository directory:
$ cd <repository_directory>

* **Step 2**: **Configure AWS Provider**
> Open the main.tf file in a text editor.
 Locate the AWS provider configuration block and update the region to your desired AWS region:
>> provider "aws" {
 >>> region = "us-east-1"
>>>> }

Configure launch template 
> Locate the AWS launch template configuration block 
>> resource "aws_launch_template" "ecs" {
  >>> count = var.create_resources ? 1 : 0
  >>>> }
  
 Configure IAM roles
> Locate the IAM provider configuration block
>> iam_instance_profile {
 >>> name = var.iam_instance_profile
 >>>> }
  
  Configure autoscaling groups
 > Locate the autoscaling provider configuration block
 >> resource "aws_autoscaling_group" "ecs" {
>>> count = local.auto_scaling_group_count
>>>> }

 Configure capacity provider
> Locate the capacity provider configuration block
>> resource "aws_ecs_capacity_provider" "capacity_provider" {
>>>  count = local.capacity_provider_count
>>>>  }

* **Step 3**: **Configure ECS Cluster**
> In the main.tf file, locate the ECS cluster module block.
>> Update the values for variables such as cluster_name, ecs_instance_type, and desired_capacity to match your requirements.

* **Step 4**: **Deploy the Infrastructure**
> Open a terminal or command prompt and navigate to the directory where the main.tf file is located.
>> Run the following command to initialize Terraform:
>>> $ **terraform init**

After initialization is complete, run the following command to preview the changes that Terraform will make:
> $ **terraform plan**

Review the planned changes and verify that they align with your expectations.

Run the following command to apply the Terraform configuration and create the resources:
> $ **terraform apply**

Review the planned changes again, and when prompted, enter yes to proceed with the resource creation.

* **Step 5**: **Verify the ECS Cluster**
> After Terraform successfully creates the ECS cluster, go to the AWS Management Console.
Navigate to the ECS service and verify that the cluster has been created.
Check the cluster's details, such as the container instances, services, and tasks.

* **Step 6**: **Cleanup**
> When you no longer need the ECS cluster, you can remove the resources to avoid incurring unnecessary costs.

Run the following command to destroy the Terraform-managed resources:
> $ **terraform destroy**
>> Review the planned actions, and when prompted, enter yes to proceed with resource deletion.

**Conclusion**
> By following the steps outlined in this guide, you can easily create an ECS cluster in AWS using Terraform. The cluster will provide a scalable and managed environment for running your containerized applications. Remember to review the Terraform documentation for further customization and to explore additional features and options provided by ECS and Terraform.

>> For any issues or questions, please refer to the repository's documentation or reach out to the project maintainer.

**Contributions**
> Contributions to this repo are very welcome and appreciated! If you find a bug or want to add a new feature or even contribute an entirely new module, we are very happy to accept pull requests, provide feedback, and run your changes through our automated test suite.







