//Author: Manish Singhal
//Date: 5th Mar 15
//Description: get() TLM method example. Producer & Consumer implemented in a UVM Environment.


`include "uvm_macros.svh"

module test;
  
  import uvm_pkg::*;
  
///////////// Transaction /////////////////  
  class my_txn extends uvm_sequence_item;
    `uvm_object_utils(my_txn)
    
    /// Data members
    typedef enum {READ, WRITE} kind_t;
    rand bit [7:0] addr;
    rand byte data;
    kind_t kind;
    
    function new (string name = "");
      super.new(name);
      kind = kind_t'($urandom_range(0,1));
    endfunction: new
    
  endclass: my_txn
  
///////////// Producer ///////////////////    
  class producer extends uvm_component;
    `uvm_component_utils(producer)
    
    ///// Export Declaration
    uvm_blocking_get_imp #(my_txn, producer) my_export;
    
    //// Constructor
    function new (string name, uvm_component parent);
      super.new(name, parent);
      my_export = new("my_export", this);
    endfunction: new
    
    //// get() task implementation
    task get(output my_txn t);
		my_txn tmp;
      	tmp = my_txn::type_id::create("tmp", this);
    	t = tmp;
      `uvm_info ("PID", $sformatf("Transaction type %s is sent", t.kind), UVM_LOW)    
    endtask: get
    
  endclass: producer
  
//////////// Consumer ///////////////////  
  class consumer extends uvm_component;
    `uvm_component_utils(consumer)
    
    //// Port Declaration
    uvm_blocking_get_port #(my_txn) my_port;
    
    function new (string name, uvm_component parent);
      super.new(name, parent);
      my_port = new("my_port", this);
    endfunction:  new
    
    task run_phase(uvm_phase phase);
      for (int i=1; i<11; i++)
        begin
        my_txn txn;
          `uvm_info("CID", $sformatf("Transaction no. %0d is asked for", i), UVM_LOW)
      	my_port.get(txn);
          #10;
          `uvm_info("CID", $sformatf("Transaction type %s is received", txn.kind), UVM_LOW);
        end
    endtask: run_phase
    
    
  endclass: consumer
  
/////////// Env /////////////////////////  
  class env extends uvm_env;
    
    producer p1;
    consumer c1;
    
    function new (string name = "env");
      super.new(name);
    endfunction: new
    //// Build Function
    function void build_phase (uvm_phase phase);
      super.build_phase(phase);
      p1 = producer::type_id::create("p1", this);
      c1 = consumer::type_id::create("c1", this);
    endfunction: build_phase
    //// Connect Function
    function void connect_phase (uvm_phase phase);
      c1.my_port.connect(p1.my_export);
    endfunction: connect_phase
    //// Run Task
    task run_phase (uvm_phase phase);
      phase.raise_objection(this);
      #1000;
      phase.drop_objection(this);
    endtask: run_phase
       
  endclass: env
  
env e; // Environment Instantiation
  
  initial
    begin
      e = new();
      run_test();
    end
    
  
endmodule: test
