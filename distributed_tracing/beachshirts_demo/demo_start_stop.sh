
# Demarrage des containers
# ------------------------
docker start wavefrontproxy
docker start jaeger


# Demarrage de l'application
# --------------------------
node /root/hackathon/distributed-tracing/node-js-app/beachshirt/app.js &


# Envoi de la charge
# ------------------
/root/hackathon/distributed-tracing/node-js-app/loadgen.sh <<< 2  > /dev/null 2>&1 &




# Wait during demo
# ----------------
echo "------------------------------------------------------------------------------"
echo "-                                                                            -"
echo "-                                                                            -"
echo "-                             DEMO IS RUNNING....                            -"
echo "- PATIENTER QUELQUES MINUTES (5-10) AVANT DE VOIR LES TRACES DANS WAVEFRONT  -"
echo "-                                                                            -"
echo "-                                                                            -"
echo "-               APPUYER SUR UNE TOUCHE POUR ARRETER LA DEMO                  -"
echo "-                                                                            -"
echo "-                                                                            -"
echo "-                                                                            -"
echo "------------------------------------------------------------------------------"


# La pause durant la demo
read a


# Stop demo
# ---------

beach_id=`ps axf | grep beach | grep -v grep | awk '{print $1}'` 
echo "beach_id=$beach_id"

loadgen_id=`ps axf | grep loadgen | grep -v grep | awk '{print $1}'`
echo "loadgen_id=$loadgen_id"

kill -9 $loadgen_id
kill -9 $beach_id
docker stop jaeger
docker stop wavefrontproxy


