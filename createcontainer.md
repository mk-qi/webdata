# createcontainer.sh

** 此工具是对docker命令使用和Ip namespace 命令的一个简单封装,使你更容易的创建一个容器,让你能够更专的把容器技术融入进你的业务逻辑中 **

###createcontainer.sh 可以为你做以下三件事情

* [创建一个容器,可以指定参数也可以不指定参数,并attach](#createhost)  
* [创建一个容器,并设定一个静态IP](#staticip)  
* [创建fanli.com的phpweb容器](#fanli)  


<a name="createhost"/>
#### create contanienr

	bash createcontainer.sh 
	----------------------equal------------------------------
	docker run --name=sh-YeDUzds --rm --net=none -it centos:6 /bin/bash --login 
		
		
		
#### 
	createcontainer.sh  --name=web2
	----------------------equal------------------------------	
	docker run --name=web2 --rm --net=none -it centos:6 /bin/bash --login 



####  
     createcontainer.sh  --name=web2 --img=centos:webdata  --cmd=ls
     ----------------------equal---------------------------------
     docker run --name=web2 --rm --net=none -it centos:webdata ls
     
#### 
     createcontainer.sh  --name=web2 --img=centos:webdata  --dockeroption= -itd
     ------------------------------------------------------------
      docker run --name=web2 -itd centos:webdata /bin/bash --login
      
  <a name="staticip"/>
#### create contanienr  with static ip

#### 
     createcontainer.sh  --name=web2 --img=centos:webdata  --ip=172.17.42.49/24 --gw=172.17.42.1
     ---------------------------------------------------------
     
     docker run --name=web2 --net=none -itd centos:webdata /bin/bash --login
     
     _set_ip_forcontainer web2 172.17.42.49/24 172.17.42.1 docker0
     
     
<a name="fanli"/>
#### create fanli phpweb
     
     createcontainer.sh  --name=webx --fanliweb
