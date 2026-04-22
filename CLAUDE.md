We are at home pc. we write code here, commit push. then pull on deploy server.
To connect to remote use ssh rymax1e-wg. It is stress12 server. to other servers you can connsct through ssh connection to this server.
To connect to stress10 or stressN use ssh rymax1e@stressN while you are at stress12.
I'm not admin. I'm in docker group only.
Don't install any big data in server memory only on mount drive in /filer/users/rymax1e.
core directory for all containers: /filer/users/rymax1e/MRO, /filer/users/rymax1e/lmstudion
This service is created to receive requests from service in /filer/users/rymax1e/MRO/report_checking. You can't change code in /filer/users/rymax1e/MRO/report_checking. This service must be designed to be able to receive request from /filer/users/rymax1e/MRO/report_checking.
On each deploy problem investifate the issue and explain me. then ask if you can fix like you propose.