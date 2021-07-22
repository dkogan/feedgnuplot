#!/bin/zsh

cat <<EOF > README.pod
=head1 TALK

I just gave a talk about this at L<SCaLE
17x|https://www.socallinuxexpo.org/scale/17x>. Here are the L<video of the
talk|https://www.youtube.com/watch?v=Qvb_uNkFGNQ&t=12830s> and the
L<"slides"|https://github.com/dkogan/talk-feedgnuplot-vnlog/blob/master/feedgnuplot-vnlog.org>.

EOF


< bin/feedgnuplot awk '/=head1/,0' >> README.pod
