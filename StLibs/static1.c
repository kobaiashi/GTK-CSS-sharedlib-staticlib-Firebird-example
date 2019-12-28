#include <stdlib.h>
#include <stdio.h>
#include "static1.h"

int staticlib_fun1(int k, int l)
{
  printf(":::::::: staticlib_fun1 ::::::\n");
  int m;
  m=k+l;
  return m;
}
