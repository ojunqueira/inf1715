.data
.text
  .globl _mul, _sub, _sum, _div
  _mul:
      pushl  %ebp
      movl   %esp, %ebp
      pushl  %ebx
      pushl  %esi
      pushl  %edi
      subl   $4, %esp	/* allocate vars on stack */
      movl   8(%ebp), %eax	/* get a from stack */
      movl   12(%ebp), %ebx	/* get b from stack */
    /* ID=rval*rval */
      movl   %eax, %ecx
      imul   %ebx, %ecx
    /*----------------*/
    /* RET_OP */
      movl   %ecx, %eax	/* save %eax for ret */
      popl   %edi
      popl   %esi
      popl   %ebx
      movl   %ebp, %esp
      popl   %ebp
      ret
    /*----------------*/
      movl   %ecx, -8(%ebp)	/* save $t1 back to stack */
  _sub:
      pushl  %ebp
      movl   %esp, %ebp
      pushl  %ebx
      pushl  %esi
      pushl  %edi
      subl   $4, %esp	/* allocate vars on stack */
      movl   8(%ebp), %eax	/* get a from stack */
      movl   12(%ebp), %ebx	/* get b from stack */
    /* ID=rval-rval */
      movl   %eax, %ecx
      subl   %ebx, %ecx
    /*----------------*/
    /* RET_OP */
      movl   %ecx, %eax	/* save %eax for ret */
      popl   %edi
      popl   %esi
      popl   %ebx
      movl   %ebp, %esp
      popl   %ebp
      ret
    /*----------------*/
      movl   %ecx, -8(%ebp)	/* save $t2 back to stack */
  _sum:
      pushl  %ebp
      movl   %esp, %ebp
      pushl  %ebx
      pushl  %esi
      pushl  %edi
      subl   $4, %esp	/* allocate vars on stack */
      movl   8(%ebp), %eax	/* get a from stack */
      movl   12(%ebp), %ebx	/* get b from stack */
    /* ID=rval+rval */
      movl   %eax, %ecx
      addl   %ebx, %ecx
    /*----------------*/
    /* RET_OP */
      movl   %ecx, %eax	/* save %eax for ret */
      popl   %edi
      popl   %esi
      popl   %ebx
      movl   %ebp, %esp
      popl   %ebp
      ret
    /*----------------*/
      movl   %ecx, -8(%ebp)	/* save $t3 back to stack */
  _div:
      pushl  %ebp
      movl   %esp, %ebp
      pushl  %ebx
      pushl  %esi
      pushl  %edi
      subl   $4, %esp	/* allocate vars on stack */
      movl   8(%ebp), %eax	/* get a from stack */
      movl   12(%ebp), %ebx	/* get b from stack */
    /* ID=rval/rval */
      movl   %ecx, -8(%ebp)	/* save $t4 back to stack */
      cltd
      idivl  %ebx	/* divide %eax by reg */
      movl   %eax, %ecx	/* set division return on correct reg */
    /*----------------*/
    /* RET_OP */
      movl   %ecx, %eax	/* save %eax for ret */
      popl   %edi
      popl   %esi
      popl   %ebx
      movl   %ebp, %esp
      popl   %ebp
      ret
    /*----------------*/
