# Script de Configuración de Espacios de Nombres de Red

Este script en Python automatiza la creación y configuración de espacios de nombres de red utilizando `pyroute2` basado en un archivo de configuración YAML. Proporciona una manera flexible de configurar topologías de red complejas para pruebas, aprendizaje o hobbies.
<br>

### Características

1. El script lee un archivo de configuración YAML.
2. Crea los espacios de nombres de red especificados.
3. Configura pares Veth para conectar espacios de nombres o con el host.
4. Crea y configura interfaces de puente según sea necesario.
5. Asigna direcciones IP estáticas a las interfaces.
6. Añade rutas estáticas para habilitar la comunicación entre espacios de nombres.
7. Ejecuta comandos personalizados para cualquier configuración adicional.

<br>

### Notas Importantes

- **Se Requieren Privilegios de Root**: Este script requiere privilegios de root para crear y configurar espacios de nombres de red. Ejecútelo con `sudo` o como usuario root.

- **Recomendado para Entornos Virtuales**: Se recomienda ejecutar este script en una máquina virtual o un entorno contenerizado. Modificar configuraciones de red en un sistema de producción puede causar interrupciones en la red y consecuencias no deseadas.

### Precauciones de Seguridad

1. Siempre pruebe este script en un entorno seguro y aislado antes de usarlo en sistemas importantes.
2. Comprenda los cambios de red que el script realizará antes de ejecutarlo.
3. Tenga un plan de respaldo o método de recuperación en caso de problemas inesperados.

Recuerde que modificar configuraciones de red puede potencialmente interrumpir la conectividad de red. Use este script de manera responsable y con precaución.

<br>

### Uso

1. Prepare su configuración de red en un archivo YAML.
2. Ejecute el script:
   ```
   python nombre_del_script.py [ruta_al_config.yaml]
   ```
   Si no se especifica un archivo de configuración, se utiliza por defecto `config/config.yaml`.

<br>

### Requisitos

- Python 3.x
- Biblioteca `pyroute2`
- Biblioteca `PyYAML`

Este script ofrece una manera poderosa y flexible de crear topologías de red virtuales utilizando espacios de nombres de red de Linux, lo que lo hace ideal para pruebas de red, desarrollo y escenarios educativos.


Espero que esto sea útil. Si necesitas más ayuda o ajustes, no dudes en decírmelo.
