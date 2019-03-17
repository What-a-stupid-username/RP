#ifndef VRP_SH_CGINC
#define VRP_SH_CGINC

#ifndef Pi
#define Pi 3.141593f
#endif

struct SH9
{
	float c[9];
};

SH9 SHCosineLobe(float3 normal)
{
	float x = normal.x; float y = normal.y; float z = normal.z;
	float x2 = x * x; float y2 = y * y; float z2 = z * z;
	SH9 sh;
	sh.c[0] = 0.28209478;							//1/2*sqrt(1/Pi)
	sh.c[1] = 0.48860251 * y;						//sqrt(3/(4Pi))
	sh.c[2] = 0.48860251 * z;
	sh.c[3] = 0.48860251 * x;
	sh.c[4] = 1.09254843 * x * y;					//1/2*sqrt(15/Pi)
	sh.c[5] = 1.09254843 * y * z;					
	sh.c[6] = 0.31539156 * (-x2 - y2 + 2 * z2);		//1/4*sqrt(5/Pi)
	sh.c[7] = 1.09254843 * z * x;
	sh.c[8] = 0.54627422 * (x2 - y2);				//1/4*sqrt(15/Pi)

	return sh;
}


#endif