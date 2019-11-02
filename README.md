[Anaconda-Archive-Link]: https://repo.continuum.io/archive/
[Pyspark-Medium-Link]: https://towardsdatascience.com/use-pyspark-with-a-jupyter-notebook-in-an-aws-emr-cluster-e5abc4cc9bdd


# emr-spark-terraform
A terraform stack for launching an AWS EMR cluster

## Connecting to EMR via JupyerLab Instructions

* Stand up resources via `terraform apply -var-file="fixtures.eu-west-1.tfvars"`
* Create jump box as EMR resources are in a private network - `TODO` implement this in Terraform
* SSH into EMR master node and set up tunnel from remote localhost:8888 to your machine port 8880
* Install Anaconda - Python 3.6 tested and working with Spark worker nodes [Anaconda Archive][Anaconda-Archive-Link]
* Add the following Environment variables to the .bashrc and reload the .bashrc script with `source .bashrc`
    
    export PYSPARK_DRIVER_PYTHON=jupyter
    export PYSPARK_DRIVER_PYTHON_OPTS='lab --no-browser --port=8888'
* Run `pyspark` which should run jupyter lab
* Open localhost:8880 in a browser on your local machine and paste an authentication token if neccesary
* When jupyter lab connects you should have a spark context `sc` ready to use.


## Resources
* [Use Pyspark with a Jupyter Notebook in an AWS EMR cluster][Pyspark-Medium-Link]