#!/bin/bash

cp /etc/phoronix-test-suite/phoronix-test-suite.xml /etc/phoronix-test-suite.xml

phoronix-test-suite batch-run ${TEST} || { 
  phoronix-test-suite batch-install ${TEST}
  phoronix-test-suite batch-run ${TEST}
}

