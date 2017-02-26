#include <iostream>

#include "math/add.h"

int hello_world();

int main(){
  std::cout<<"please enter two integer:"<<std::endl;

	int a,b;
  std::cin>>a>>b;

  std::cout<<"add("<<a<<","<<b<<") returns "<<add(a,b)<<std::endl;

	hello_world();
}
