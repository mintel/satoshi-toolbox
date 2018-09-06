# satoshi-toolbox
A toolbox container to ensure team members share a common Toolset

## TEST

```docker run --name satoshi --rm -d -v /dev/usb:/dev/usb --privileged -v ~/:/home/satoshi satoshi-toolbox:test```
```docker exec -t -i satoshi bash```
