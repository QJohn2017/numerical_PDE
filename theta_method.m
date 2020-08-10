function [U_all,errL1_all,errL2_all,errInf_all,orderL1_all,orderL2_all,orderInf_all,h_all,k_all]=theta_method(type,theta)
%pde:     ut=uxx+f(x,t), x in [a,b], t in [0,T]
%�߽�����: u(a)=ua, u(b)=ub, t in [0,T]
%��ʼ����: u(x,0)=v, x in [a,b] % U_ini
% type=th01,th01_sym,th02,th02_sym �ǶԳƣ��Գ�
a=0;b=1;ini_t=0;end_t=1;flag=0;
M=[10 20 30 40 80 160 320];
N=[10 20 30 40 80 160 320];
U_all=cell(1,length(M));
errL1_all=zeros(length(M),1);
errL2_all=zeros(length(M),1);
errInf_all=zeros(length(M),1);
h_all=zeros(length(M),1);
k_all=zeros(length(M),1);
orderL1_all=zeros(length(M)-1,1);
orderL2_all=zeros(length(M)-1,1);
orderInf_all=zeros(length(M)-1,1);
for i=1:length(M)
    [U,errL1,errL2,errInf,h,k]=Solver(type,theta,a,b,ini_t,end_t,M(i),N(i),flag);
    U_all{i}=U;
    errL1_all(i)=errL1;
    errL2_all(i)=errL2;
    errInf_all(i)=errInf;
    h_all(i)=h;
    k_all(i)=k;
end
for i=2:length(M)
    orderL1_all(i-1) = log(errL1_all(i)/errL1_all(i-1))/log(h_all(i)/h_all(i-1));
    orderL2_all(i-1) = log(errL2_all(i)/errL2_all(i-1))/log(h_all(i)/h_all(i-1));
    orderInf_all(i-1) = log(errInf_all(i)/errInf_all(i-1))/log(h_all(i)/h_all(i-1));
end
end

function [U_numerical_final,errL1,errL2,errInf,h,k]=Solver(type,theta,a,b,ini_t,end_t,M,N,flag)
%��һ�� �����ʷ�
k=(end_t-ini_t)/N; h=(b-a)/M;
P=[a:h:b-a]';

%�ڶ��� ��������������
u=@(x,t)(x.^2-x).*cos(2*pi*t);
rhs=@(x,t)2*pi*sin(2*pi*t)*(-x.^2+x)-2*cos(2*pi*t);
U_ini=feval(u, P, 0);

%������ ���
[U,U_all]=theta_scheme_1D(type,theta,U_ini,P,k,N,h,M,u,rhs);

%���Ĳ����������
U_numerical_final=U;
vector_uexact_final = feval(u,P,end_t);
if strcmp(type,'th01_sym')||strcmp(type,'th02_sym')
    ua=feval(u,a,end_t);ub=feval(u,b,end_t);
    U_numerical_final=[ua;U;ub];
    U_all=[ua*ones(1,N);U_all;ub*ones(1,N)];
end
vec_err=vector_uexact_final-U_numerical_final;
errL1=norm(vec_err,1);
errL2=norm(vec_err,2);
errInf=norm(vec_err,inf);

%���岽 ��ͼ
if flag==1
    figure; hold on
    for ki=1:10
        plot(P,U_all(:,ki),'--+r');
        Uexact = feval(u,P,ki*k);
        plot(P,Uexact,'-sb');
        legend('numerical solution','exact solution');
    end
    grid on; xlabel x; ylabel y; hold off
    figure
    fsurf(u,[a b ini_t end_t]);
    [t,x]=meshgrid(ini_t:k:end_t-k,a:h:b);
    figure
    surf(x,t,U_all,'EdgeColor','none');
    axis tight
end
end

function [U,U_all]=theta_scheme_1D(type,theta,U_ini,P,k,N,h,M,u,rhs)
if strcmp(type,'th01')
    [U,U_all]=solver_th01(theta,U_ini,P,k,h,N,M,rhs);
elseif strcmp(type,'th01_sym')
    [U,U_all]=solver_th01_sym(theta,U_ini,P,k,h,N,M,u,rhs);
elseif strcmp(type,'th02')
    [U,U_all]=solver_th02(theta,U_ini,P,k,h,N,M,u,rhs);
elseif strcmp(type,'th02_sym')
    [U,U_all]=solver_th02_sym(theta,U_ini,P,k,h,N,M,u,rhs);
else
end
end

function [U,U_all]=solver_th01(theta,Uold,P,k,h,N,M,rhs)
A=sparse(M+1,M+1);
F=zeros(M+1,1);
U_all=zeros(M+1,N);
I=eye(M+1);
lambda=k/(h^2);
for n=1:N
    tn=n*k;tpre=tn-k;
    for j=2:M
        A(j,[j-1,j,j+1])=[1,-2,1];
        F(j,1)=k*theta*feval(rhs,P(j),tn)+k*(1-theta)*feval(rhs,P(j),tpre);
    end
    Ftotal=(I+(1-theta)*lambda*A)*Uold+F;
    Atotal=I-theta*lambda*A;
    U=Atotal\Ftotal;
    Uold=U;
    U_all(:,n)=U;
end
end

function [U,U_all]=solver_th01_sym(theta,Uold,P,k,h,N,M,u,rhs)
A=sparse(M-1,M-1);
F=zeros(M-1,1);G=zeros(M-1,1);
U_all=zeros(M-1,N);
I=eye(M-1);
lambda=k/(h^2);
Uold=Uold(2:M);
for n=1:N
    tn=n*k;tpre=tn-k;
    A(1,[1,2])=[-2,1];
    G(1,1)=theta*lambda*feval(u,P(1),tn)...
        +(1-theta)*lambda*feval(u,P(1),tpre);
    F(1,1)=k*theta*feval(rhs,P(2),tn)+k*(1-theta)*feval(rhs,P(2),tpre);
    A(M-1,[M-2,M-1])=[1,-2];
    G(M-1,1)=theta*lambda*feval(u,P(M+1),tn)...
        +(1-theta)*lambda*feval(u,P(M+1),tpre);
    F(M-1,1)=k*theta*feval(rhs,P(M),tn)+k*(1-theta)*feval(rhs,P(M),tpre);
    for j=2:M-2
        A(j,[j-1,j,j+1])=[1,-2,1];
        F(j,1)=k*theta*feval(rhs,P(j+1),tn)+k*(1-theta)*feval(rhs,P(j+1),tpre);
    end
    Ftotal=(I+(1-theta)*lambda*A)*Uold+F+G;
    Atotal=I-theta*lambda*A;
    U=Atotal\Ftotal;
    Uold=U;
    U_all(:,n)=U;
end
end

function [U,U_all]=solver_th02(theta,Uold,P,k,h,N,M,u,rhs)
A=sparse(M+1,M+1);
B=sparse(M+1,M+1);
F=zeros(M+1,1);G=zeros(M+1,1);
U_all=zeros(M+1,N);
lambda=k/(h^2);
for n=1:N
    tn=n*k;tpre=tn-k;
    for j=1:M+1
        if j==1
            A(1,1)=1;
            G(1,1)=feval(u,P(1),tn);
        elseif j==M+1
            A(M+1,M+1)=1;
            G(j,1)=feval(u,P(M+1),tn);
        else
            A(j,[j-1,j,j+1])=[-theta*lambda,1+2*theta*lambda,-theta*lambda];
            B(j,[j-1,j,j+1])=[(1-theta)*lambda,1-2*(1-theta)*lambda,(1-theta)*lambda];
            F(j,1)=k*theta*feval(rhs,P(j),tn)+k*(1-theta)*feval(rhs,P(j),tpre);
        end
    end
    Ftotal=B*Uold+F+G;
    U=A\Ftotal;
    Uold=U;
    U_all(:,n)=U;
end
end

function [U,U_all]=solver_th02_sym(theta,Uold,P,k,h,N,M,u,rhs)
A=sparse(M-1,M-1);
B=sparse(M-1,M-1);
F=zeros(M-1,1);G=zeros(M-1,1);
U_all=zeros(M-1,N);
lambda=k/(h^2);
Uold=Uold(2:M);
for n=1:N
    tn=n*k;tpre=tn-k;
    for j=1:M-1
        if j==1
            A(1,[1,2])=[1+2*theta*lambda,-theta*lambda];
            B(1,[1,2])=[1-2*(1-theta)*lambda,(1-theta)*lambda];
            G(1,1)=theta*lambda*feval(u,P(1),tn)...
                +(1-theta)*lambda*feval(u,P(1),tpre);
        elseif j==M-1
            A(M-1,[M-2,M-1])=[-theta*lambda,1+2*theta*lambda];
            B(M-1,[M-2,M-1])=[(1-theta)*lambda,1-2*(1-theta)*lambda];
            G(j,1)=theta*lambda*feval(u,P(j+2),tn)...
                +(1-theta)*lambda*feval(u,P(j+2),tpre);
        else
            A(j,[j-1,j,j+1])=[-theta*lambda,1+2*theta*lambda,-theta*lambda];
            B(j,[j-1,j,j+1])=[(1-theta)*lambda,1-2*(1-theta)*lambda,(1-theta)*lambda];
        end
        F(j,1)=k*theta*feval(rhs,P(j+1),tn)+k*(1-theta)*feval(rhs,P(j+1),tpre);
    end
    Ftotal=B*Uold+F+G;
    U=A\Ftotal;
    Uold=U;
    U_all(:,n)=U;
end
end
