Install vsphere storage for k8s:

https://vmware.github.io/vsphere-storage-for-kubernetes/documentation/existing.html

- Copy config file to /etc/kubernetes
- Add to kubelet configuration:
    ```
    --cloud-provider=vsphere
    --cloud-config=/etc/kubernetes/vsphere.conf
    ```

