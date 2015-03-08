// Code your testbench here
// or browse Examples
// Author: Manish Singhal
// Date: 8th March 2015
// Description: Example show how to connect a TLM producer and TLM consumer using a 'uvm_tlm_fifo' which a non-blocking way of connection.

`include "uvm_macros.svh"

module test;
  
  import uvm_pkg::*;

  /// Transaction declaration
  class my_txn extends uvm_sequence_item;
    `uvm_object_utils(my_txn)
    
    /// Data members
    typedef enum {READ, WRITE} kind_t;
    kind_t kind;
    rand bit [7:0] addr;
    rand byte data;
    
    // Constructor
    function new (string name = "");
      super.new(name);
      kind = kind_t'($urandom_range(0,1));
    endfunction: new
    
  endclass: my_txn
  
  /// Producer declaration
  class producer extends uvm_component;
    `uvm_component_utils(producer)
    
    /// put port declaration
    uvm_blocking_put_port #(my_txn) my_put_port;
    
    /// Constructor
    function new (string name, uvm_component parent);
      super.new(name, parent);
      my_put_port = new("my_put_port", this);
    endfunction: new
    
    /// Run task
    task run_phase (uvm_phase phase);
      for(int i=1; i<11; i++)
        my_txn txn;
      txn = my_txn::type_id::create("txn", this);
      my_put_port.put(txn);
      `uvm_info("PID", $sformatf("Transaction no. %0d sent as %s", i, txn.kind), UVM_LOW);
    endtask: run_phase
    
  endclass: producer
  
  /// Consumer declaration
  class consumer extends uvm_component;
    `uvm_component_utils(consumer)
    
    /// get port declaration
    uvm_blocking_get_port #(my_txn) my_get_port;
    
    /// Constructor
    function new (string name, uvm_component parent);
      super.new(name, parent);
      my_get_port = new("my_get_port", this);
    endfunction
    
    /// Run task
    task run_phase (uvm_phase phase);
      for(int ii=1; ii<11; ii++)
        my_txn t;
      t = my_txn::type_id::create("t", this);
      my_get_port.get(t);
      `uvm_info("CID", $sformatf("Transaction no. %0d is received as %s", ii, t.kind), UVM_LOW);
    endtask: run_phase
    
  endclass: consumer
  
  /// Environment declaration
  class env extends uvm_env;
    
    /// Instance declaration
    uvm_tlm_fifo #(my_txn) my_tlm_fifo;
    producer p1;
    consumer c1;
    
    /// Constructor
    function new (string name = "env");
      super.new(name);
      my_tlm_fifo = new("my_tlm_fifo", this);
    endfunction: new
    
    /// Build function
    function void build_phase (uvm_phase phase);
      super.build_phase(phase);
//      my_tlm_fifo = new("my_tlm_fifo", this);
      p1 = producer::type_id::create("p1", this);
      c1 = consumer::type_id::create("c1", this);
    endfunction: build_phase
    
    // Connect function
    function void connect_phase (uvm_phase phase);
      p1.my_put_port.connect(my_tlm_fifo.put_export);
      c1.my_get_port.connect(my_tlm_fifo.get_export);
    endfunction: connect_phase
    
    /// Run phase
    task run_phase (uvm_phase phase);
      phase.raise_objection(this);
      #1000;
      phase.drop_objection(this);
    endtask: run_phase
    
  
  endclass: env
    
  env e;
  
  initial
    begin
      e = new();
      run_test();
    end
      
endmodule: test
