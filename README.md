# ldd-apple
A more ldd like tool for macos to investigate dylib dependencies

I am more of a linux guy and I was annoyed by the fact that apply does not have a real alternative to `ldd`. There is `otool -L` of course but it performs a static analysis that does not really tell you want might happen at runtime like ld do (see https://stackoverflow.com/a/67818942/6189172)

So starting from the idea of Cris (https://stackoverflow.com/a/56248596/6189172) and overcoming the problem [SIP](https://apple.co/3sDkQZJ) that would not allow some environemt variable to work properly for security reason, I came up with this:

```shell
ldd-apple.sh [either a dylib or an executable]
```

This basically injects a dynamic library while trying to run simple executable that print environment variables, with the idea of trying to see if the library can be loaded at runtime.

Ah... and there in one more thing... it also work with an executable, if it is not restricted. You can check if it restricted by running on macOS

```shell
/bin/ls -lOL <executable>
```

Most of the command like tools for example are restricted...


```shell
❯ /bin/ls -lOL /usr/bin/true
-rwxr-xr-x  1 root  wheel  restricted,compressed 100512 24 Aug 09:59 /usr/bin/true
```