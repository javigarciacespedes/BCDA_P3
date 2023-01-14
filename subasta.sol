// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
// HECHO POR: JAVIER GARCIA CESPEDES, ALVARO DE BLAS Y JUAN FRANCISCO VARA
contract Subasta {

    // Usuario que organiza la subasta.
    address owner;
    
    ///  Descripcion del producto subastado
    string public producto;
    uint pujaMaxima = 0;
    // Importe de las fianzas pagadas.
    // La clave es la direccion del usuario.
    // El valor es la fianza pagada.
    // El valor es 0 para los usuarios que no se han registrado nunca, y
    // para los usuarios a los que ya se les ha devuelto su fianza.
    mapping (address => uint) fianzaPagada;

    //Candado para evitar la reentrada de código
    bool locked = false;
    // Array con las direcciones de todos los usuarios registrados.
    address[] registrados;

    // Usuario que ha realizado la mayor puja hasta el momento.
    address payable public ganador;

    // Fianza de registro: ingresarlo para participar en la subasta.
    uint constant fianza = 5000;

    // Si la subasta esta abierta, se puede pujar.
    // Si esta cerrada, ya no se puede pujar, y el producto subastado
    // se le asigna al usuario ganador (el que hizo la puja mas alta).
    enum Estado { Abierta, Cerrada } 

    // El estado de la subasta.
    Estado public estado;
    
    constructor(string memory _producto) {
        owner = msg.sender;
        producto = _producto;
    }

    // Para participar en la subasta, hay que registrarse antes.
    // Para registrarse hay que ingresar una  fianza, que se devuelve cuando 
    // termina la subasta.
    function registrarse() onlyNoRegistrado public payable {
        // Comprobar que se ha ingresado por lo menos la fianza requerida.
        // Ojo: estoy poniendo >= 
        require(msg.value == fianza, "Debe enviar el dinero de la fianza.");

        // Guardo los datos del registro.
        fianzaPagada[msg.sender] = msg.value;
        registrados.push(msg.sender);
    }

    // Hacer una nueva puja. Hay que enviar el importe de la puja realizada.
    function pujar() onlyAbierta public payable { //cambiar por onlyAbierta
        // Comprobar que la nueva puja es mayor que la puja ganadora actual.
        // El valor de la nueva puja es igual al dinero recibido.
        // El valor de la puja ganadora actual es igual al balance del 
        // contrato restando las fianzas acumuladas y el dinero recibido por 
        // la nueva puja.
        // Cuidado: El importe total de las fianzas recibidas se esta 
        // calculando multiplicando el valor de la constante fianza por el
        // numero de registros.
        //uint totalFianzas = fianza * registrados.length;
        //require(msg.value > fianza, "La puja debe ser superior a la fianza."); //La puja debe ser superior a la fianza depositada
        uint pujaNueva = msg.value;
        //uint pujaAnterior = address(this).balance-totalFianzas-msg.value;
        require(pujaNueva > pujaMaxima, "Cada puja debe ser mayor que la anterior.");
        pujaMaxima = pujaNueva;
        // Actualizar quien es el nuevo usuario ganador.
        ganador = payable(msg.sender);

        // Devolver el dinero pujado al usuario ganador anterior.
        ganador.transfer(pujaMaxima);


    }
/*
    // Terminada la subasta, hay que devolver las fianzas a los usuarios.
    function devolverFianza() onlyOwner public { //Cambiar por onlyOwner
        for (uint i = 0 ; i < registrados.length ; i++) {
            address addr = registrados[i];
            if (fianzaPagada[addr] > 0) {
                (bool ok,) = addr.call{value: fianzaPagada[addr]}("");
                require(ok, "No se ha podido devolver la fianza");
                fianzaPagada[addr] = 0;
            }
        }
    }
*/
    // Terminada la subasta, cada usuario recibe su fianza. 
    /*
        Dos maneras: 
            1.- Poner un candado
            2.- Cambiar el valor de la variable antes de hacer el pago
    */
    function devolverMiFianza() onlyRegistrado public {
        require(locked == false, "Llamada reentrante detectada.");
            locked = true;
            address addr = msg.sender;
            uint aux_pagar = fianzaPagada[addr];
            fianzaPagada[addr] = 0;
            addr.call{value: aux_pagar};
            locked = false;

    }


    // Cerrar la subasta. Ya no se puede pujar mas.
    function cerrar() onlyOwner onlyAbierta public {
        estado = Estado.Cerrada;
    }
    modifier onlyOwner() {
        require(msg.sender == owner, "Solo permitido para owner");
        _;
    }
    modifier onlyAbierta {
         require(estado == Estado.Abierta, "Debe estar Abierta");
         _;
    }
    modifier onlyCerrada {
         require(estado == Estado.Cerrada, "Debe estar Cerrada");
         _;
    }
    modifier onlyRegistrado {
         require(fianzaPagada[msg.sender] > 0, "Debe estar registrado");
         _;
    }
    modifier onlyNoRegistrado {
         require(fianzaPagada[msg.sender] == 0, "No debe estar registrado");
         _;
    }
    receive() external payable {
        revert();
    }  
}