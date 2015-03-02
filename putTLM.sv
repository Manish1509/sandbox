// Code your testbench here
// or browse Examples

`include "uvm_macros.svh"
//`include "uvm.svh"

module test;
  
import uvm_pkg::*;

 class txn extends uvm_sequence_item;
    `uvm_object_utils(txn)
    
   typedef enum {READ, WRITE} kind_t;
//   typedef enum {WRITE} kind_t;
//   enum {READ, WRITE} kind;
//   kind = READ;
    rand bit [7:0] addr;
    rand byte data;
    rand kind_t kind;
//   string kind = READ;
        
    function new (string name = "");
      super.new(name);
//      kind = WRITE;
//      kind = $urandom_range(0,1);
    endfunction: new
    
 endclass: txn

class producer extends uvm_component;
  `uvm_component_utils(producer)
//  uvm_blocking_put_port #(int) my_port;
  uvm_blocking_put_port #(txn) my_port;
  
  function new (string name, uvm_component parent);
    super.new(name, parent);
    my_port = new ("my_port", this);
  endfunction: new
  
  task run_phase(uvm_phase phase);
    for (int packet = 1; packet<11; packet++)
      begin
        txn t;
        t = txn::type_id::create("t", this);
        //      my_port.put(packet);
        `uvm_info("PID", $sformatf("Packet no. %d is sent", packet), UVM_LOW)
//      my_port.put(packet);
        my_port.put(t);
        #10;
      end
  endtask: run_phase
endclass: producer


class consumer extends uvm_component;
  `uvm_component_utils(consumer)
//  uvm_blocking_put_imp #(int, consumer) my_export;
  uvm_blocking_put_imp #(txn, consumer) my_export;
  
  function new (string name, uvm_component parent);
    super.new(name, parent);
    my_export = new("my_export", this);
  endfunction: new
  
//  task put (int p);
//    `uvm_info("RID", $sformatf("Packet no. %d Receieved", p), UVM_MEDIUM);
//    endtask: put
  task put (txn t);
    case(t.kind)
      t.READ: $display("Read transaction");
      t.WRITE: $display("Write transaction");
//    `uvm_info("RID", $sformatf("Packet no. %d Receieved", p), UVM_MEDIUM);
    endcase
    endtask: put
endclass: consumer


class env extends uvm_env;
//  `uvm_component_utils(env)
  
//  producer p1;
//  consumer c1;
  
  function new (string name = "env");
    super.new(name);
  endfunction: new
  
  producer p1;
  consumer c1;
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    p1 = producer::type_id::create("p1", this);
    c1 = consumer::type_id::create("c1", this);
  endfunction: build_phase
    
  function void connect_phase(uvm_phase phase);
    p1.my_port.connect(c1.my_export);
  endfunction: connect_phase  
  
  task run_phase(uvm_phase phase);
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
