#define _DEFAULT_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <unistd.h>

/* Only this launcher is exposed through the NixOS setuid wrapper. */
int main(int argc, char **argv) {
    if (argc < 1) return 1;
    umask(077);
    if (chdir("/") != 0 || clearenv() != 0 ||
        setenv("PATH", VPN_PATH, 1) != 0 ||
        setenv("HOME", "/root", 1) != 0 ||
        setenv("LC_ALL", "C", 1) != 0 ||
        setenv("SSL_CERT_FILE", "/etc/ssl/certs/ca-bundle.crt", 1) != 0) {
        perror("svpn: setting a trusted environment");
        return 1;
    }
    argv[0] = (char *)VPN_EXEC;
    execv(VPN_EXEC, argv);
    perror("svpn: exec");
    return 127;
}
