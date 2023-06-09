# Alpine_hadoop

### Image size: 1.54G

### Primero

- Se debe descargar hadoop-3.3.5.tar.gz y se debe ubicar justo al lado del Dockerfile
- Se debe descargar jdk-8u371-linux-x64.tar.gz y se debe ubicar justo al lado del Dockerfile

### Ejecutar una vez

1. Iniciar docker swarm

```bash
docker swarm init --advertise-addr 127.0.0.1
```

2. Crear la network

```bash
docker network create --driver overlay swarm-net
```

### Construcción de la imágen y deployment

3. Construir la imagen

```bash
docker build -t hadoop_alpine .
```

4. Correr los contenedores

```bash
docker stack deploy -c docker-compose.yaml swarm
```

### Como funciona?

Al montarse los esclavos estos mandan sus llaves al maestro (~/.ssh/config, ~/.ssh/authorized_keys y /opt/hadoop/etc/hadoop/workers)

Todos tienen el usuario `hadoop` con la contraseña `1234`
Los esclavos deben tener las variables de entorno:

```bash
MASTER_HADOOP_PASSWORD=<contraseña del maestro (usuario hadoop)>
MASTER_HOSTNAME=<hostname del maestro>
```

El nodo maestro no debe mandar ninguna variable de entorno, sin embargo una vez montado es deber del usuario mandar sus llaves a todos los nodos hijo, esto se puede hacer fácilmente entrando al contenedor maestro (con `docker container exec -it <container> bash` y `su -l hadoop`) y ejecutando:

```bash
ssh_config="Host $(hostname)\nUser hadoop\nHostname $(hostname -i | cut -d ' ' -f 1)"; echo -e $ssh_config >> /home/hadoop/.ssh/config

cat /home/hadoop/.ssh/id_ed25519.pub >> /home/hadoop/.ssh/authorized_keys

```

Remover `localhost` del archivo `/opt/hadoop/etc/hadoop/workers`

```bash
while read p; do < /home/hadoop/.ssh/authorized_keys sshpass -p "1234" ssh -o StrictHostkeyChecking=no "$p" 'cat >> /home/hadoop/.ssh/authorized_keys'; < /home/hadoop/.ssh/config sshpass -p "1234" ssh -o StrictHostkeyChecking=no "$p" 'cat >> /home/hadoop/.ssh/config'; done < /opt/hadoop/etc/hadoop/workers

```

Finalmente el nodo maestro inicia el servicio

```bash

hdfs namenode -format

start-dfs.sh

```

#### Consideraciones

Iniciar el servicio siendo root no le gusta a hadoop y manda error, se debe iniciar como usuario `hadoop`

Refrescar los namenodes

```bash
while read p; do hdfs dfsadmin -refreshNamenodes "$p":9867; done < /opt/hadoop/etc/hadoop/workers
```

#### TODO:

1. Crear un .env para manejar la construcción de la imágen (hadoop y oracle java)
2. Mejorar el script del entrypoint
