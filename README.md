# Basic Boundary reference architecture/demo environment

## Using this repo

There are four  stages to bootstrapping Boundary using the files in this repo after cloning it:

* Make sure your environment contains AWS credentials in a form that will be available to the Terraform `aws` provider (AWS credential file or standard environment variables).  These credentials will need pretty much unrestricted access to your AWS environment (at a minimum, create a VPC and associated network infrastructure, create roles and security groups, create instances, and have an SSH key available to use)

1. Determine your settings for the environment.  At a minimum you must supply an SSH key name in the variable `aws_ssh_keypair`.  You may also wish to set a region (`aws_region`, defaults to us-east-2), a name for the environment (`unique_name`, defaults to "boundary_demo") or a preferred AMI (`aws_instance_ami`, defaults to a Flatcar Linux AMI).  This Terraform code will try to determine your external IP to set on the AWS security group; to override this determination, set the list of subnets to allow with `admin_ips`.  There are other options you can set as well; see `variables.tf` for details.
2. `terraform init && terraform plan && terraform apply`
This will create the following infrastructure:
* A VPC
  * Two public subnets
    * Subnet 1:
      * A "utility" server running Vault and Postgres for Boundary's use
      * A "bootstrap" server to run Boundary-related database operations like init and migrate that require DB superuser credentials
      * A set of one or more Boundary controllers
      * A plain Boundary worker with no worker tags
      * A Boundary worker marked with a "docker" tag
    * Subnet 2:
      * (reserved for future EKS use)
  * One private subnet
    * Three instances usable as web app hosts.
Note that these three instances, by design, are not accessible via SSH until after Boundary SSH targets are set up.
* Several files that will be used to bootstrap Boundary's infrastructure in the environment
3. Copy files and start services.
   1. `bash boundary-startup-infra.sh`: this will copy files, then SSH to the utility server and start up Vault and Postgres
   2. `bash boundary-startup-bootstrap.sh`: this will copy files, then SSH to the bootstrap server and start `boundary database migrate`.  If this is successful, you will see a dump of initial Boundary auth info after it completes.
   3. `bash boundary-startup-controller.sh`: this will start up the controller(s).  At this point you should be able to log in to Boundary at `http://[any controller public IP]:9200`
   4. `bash boundary-startup-workers.sh`: Start up the Boundary workers that will connect to the various targets.
3. Configure Boundary.  This will consist of constructing the host catalog, host sets, and hosts, along with various targets; this is where you will want to dive into the documentation at the [Boundary website](https://boundaryproject.io/).  Some suggestions:

* Start by creating a host catalog (this has deliberately been skipped as part of the setup of this environment)
* Add single-host host sets for the Boundary utility server, the Boundary controller, and each of the Boundary workers.
  * Add an HTTP target for Vault on port 8200 and one for Postgres on port 5432 on the utility server host set.
  * Add an SSH target for each host set. 
* Add a host set for the web hosts (their private IP addresses are found in the `boundary_instance_http_private_ipaddrs` section of `terraform output`)
  * Configure an SSH target for shell access to the web hosts.
    * Note that if you want to consistently access a specific host through this target, you must supply its host ID to `boundary connect ssh`; otherwise, you will be connected to a randomly-chosen host).
  * Using the web host SSH target and the web host IDs, SSH to each web host and set up an instance of a web app, then create an HTTP target for that host set.
    * Note that if you use `boundary connect` without an overlay to open a proxy so you can use a web browser over the proxied connection, the default target configuration limits the session to one connection.  Many GUI web browsers make requests for content like robots.txt or favicon.ico before requesting the page data -- in this case the browser will exhaust the one allowed connection on those requests and then get an error for the page request.  When using a GUI web browser with `boundary connect` to a target (either with or without the `http` overlay), it is recommended to allow a large number or unlimited connections per session.
    * Since the `http` Boundary connect overlay actually defaults to using HTTPS, if your test app is HTTP-only, use the `-scheme http` option when connecting with `boundary connect http`.
    * If you don't have anything handy to run, you can run this: `docker run -d -p 8080:80 valian/docker-nginx-test-page` on each one -- this will start a basic test app that will output the hostname and external IP address of the container over HTTP on host port 8080.  Note that because these instances have no public IPs, what you'll see in the output of the container through `boundary connect http` will always be the public IP of the NAT gateway, but the container hostnames will vary with repeated requests.  
* SSH to the Docker worker host (either directly or via setting up and using a Boundary target) and start a web app container there that is *not* port-forwarded from the host.  A default nginx container is fine: `docker run -d nginx`
  * Add a host set for the Docker container's local IP (you can find it with `docker inspect`).
  * Add a target that uses a filter on the "type = docker" worker tag to ensure that all access to that host set via that target goes through that worker (as it will not be consistently accessible otherwise).
  * Add a target just like the previous that lacks the filter.  Experiment.
* Add targets with short session times -- these would be ideal for limiting use by less-trusted users or for running non-interactive commands that just dump info.
* Add a user who has access to only specific targets.

## Important notes

* If things look a little scattershot organizationally, I can only -- SQUIRREL!
* This demo architecture is *not production-ready*.  Do not use it in a production scenario and *DO NOT* store any sensitive information in it.  Treat it as completely disposable.  Most notably:
  * Nothing is TLS-enabled (except the Boundary-to-Boundary traffic that Boundary does this for automatically), to enable easily inspecting traffic flows should you wish to.
  * Vault is run in dev mode; if the Vault service is restarted after the environment is stood up, all Vault key data will be lost and you will need to manually reset (or just destroy and recreate).
  * Postgres data is stored in a directory on the utility server disk.
  * Vault tokens and Postgres credentials are not separated with minimal permissions for Boundary components as they should be in a properly-secure environment.
  * Nothing but Vault runs as a non-root user inside the containers.
* If you need to debug failures during standup, the following systemd units will be relevant:
  * Utility server: `vault`, `postgres`
  * Bootstrap server: `vault-init`, `boundary-database-init`, `boundary-database-migrate`
  * Boundary controller(s): `boundary-controller`
  * Boundary workers: `boundary-worker`
* There are bits and pieces of future improvements already embedded throughout this repo.  Consider them a sneak preview :)

## TODO

* TLS throughout
* Improve basic infra provisioning (BYO VPCs/subnets/gateways)
* Improve Boundary dep provisioning
  * Add options for AWS-native deps (KMS/RDS)
  * Preconfigure Vault and Postgres service units (Ignition config)
* Improve Boundary component provisioning
  * LB fronting controllers
  * Separate init and controller DB credentials
  * Run Postgres/Boundary containers as non-root users
  * Preconfigure waiter/database init/controller/worker units (Ignition config)
  * Database init changes
    * Skip automatic auth provisioning and replace with Terraform Boundary resources
  * Genericise template (worker tags, worker/controller-specific config sections)
* Improve target provisioning
  * Add EKS infrastructure, worker and http/kube targets
  * Prestart target apps (Ignition config)
  * Preconfigure SSH, web and worker-local Docker targets
  * Add targets through Terraform Boundary resources
