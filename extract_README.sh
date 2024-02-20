#!/bin/zsh

cat <<EOF > README.pod
=head1 TALK

I just gave a talk about this at L<SCaLE
17x|https://www.socallinuxexpo.org/scale/17x>. Here are the L<video of the
talk|https://www.youtube.com/watch?v=Qvb_uNkFGNQ&t=12830s> and the
L<"slides"|https://github.com/dkogan/talk-feedgnuplot-vnlog/blob/master/feedgnuplot-vnlog.org>.

EOF

seq 5 | awk '{print 2*$1, $1*$1}' |
   feedgnuplot               \
     --lines                 \
     --points                \
     --title "Test plot"     \
     --y2 1                  \
     --unset key             \
     --unset grid            \
     --hardcopy 'documentation-header-plot.svg'


< bin/feedgnuplot                                                          \
  awk '/^ *Test plot$/,/^ *1 +1.5 +2 +2.5/                                 \
       { if(!wrote_plot1) { print "=for html <p><img src=\"documentation-header-plot.svg\">"; \
                            wrote_plot1 = 1; }                             \
         next;                                                             \
       }                                                                   \
       /^ *wlan0 throughput$/,/seconds/                                    \
       { if(!wrote_plot2) { print "=for html <p><img src=\"documentation-header-network-throughput-plot.svg\">"; \
                            wrote_plot2 = 1; }                             \
         next;                                                             \
       }                                                                   \
       /=head1/,0                                                          \
       { print }' >> README.pod

