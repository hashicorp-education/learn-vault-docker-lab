# -----------------------------------------------------------------------
# Global variables
# -----------------------------------------------------------------------

# Set TF_VAR_docker_host to override this
# tcp with hostname example:
# export TF_VAR_docker_host="tcp://docker:2345"

variable "docker_host" {
  default = "unix:///var/run/docker.sock"
}
