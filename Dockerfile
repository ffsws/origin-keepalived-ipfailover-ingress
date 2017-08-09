#
# Ingress VIP failover monitoring container for OpenShift.
#
# ImageName: quay.io/appuio/origin-keepalived-ipfailover-ingress
#
FROM openshift/origin

RUN INSTALL_PKGS="kmod keepalived iproute psmisc nmap-ncat net-tools" && \
    yum install -y $INSTALL_PKGS && \
    rpm -V $INSTALL_PKGS && \
    yum clean all
COPY . /var/lib/ipfailover/keepalived/

LABEL io.k8s.display-name="OpenShift Origin Ingress IP Failover" \
      io.k8s.description="This container runs a clustered keepalived instance across multiple hosts to allow highly available IP addresses for non-http ingress."
#EXPOSE 1985
WORKDIR /var/lib/ipfailover
ENTRYPOINT ["/var/lib/ipfailover/keepalived/run.sh"]
