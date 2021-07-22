#!/bin/zsh

< bin/feedgnuplot awk '/=head1/,0' > README.pod
