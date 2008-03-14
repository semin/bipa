/*
 * Calculate accessible surface area
 *
 */


/**************START**************/

#include "gen.h"
#include "read_RadiiLib.h"
#include "read_pdb.h"
#include "contact.h"
#include <stdio.h>
#include <string.h>
#include <math.h>
#include <unistd.h>
#ifdef MEMDEBUG
	#include "memdebug.h"
#endif


MYREAL *contact(PDBREC *MyPdbRec, MYREAL *radius, MYREAL ProbeSize, MYREAL IntegrationStep,
		boolean flag_Verbose)
{
register int 	i, j, k;

PDBATOM		**Array_PdbAtom;
PDBATOM		*current_ptr_atom;
PDBATOM		**current_ptr_cubeatom;
PDBATOM		*temp_ptr_atom;
PDBATOM		**NeighborAtom;
CUBEINFO	***cubes;
CUBEINFO	*current_ptr_cube;
CUBEINFO	**atom2cube;
CUBEINFO	*TempCubes[27];
CUBEINFO	*TempCubes_ptr;
CUBEINFO	**cubes_LV2;
CUBEINFO	*cubes_LV1;

MYREAL		*SurfaceRadius;
MYREAL		*SurfaceRadiusSQR;
MYREAL		*access;
MYREAL		TempDouble;
MYREAL		MaxRadius;
MYREAL		xmin, xmax;
MYREAL		ymin, ymax;
MYREAL		zmin, zmax;

int		Num_Layer;
int		Num_NeighborAtom;
int		Num_AllAtom;
int		Num_TempCubes;
int		Num_CubeX;
int		Num_CubeY;
int		Num_CubeZ;
int		index;
int		TempInt;
int		TempInt2;
int		TempI, TempJ, TempK;
int		Max_Intersection;
int		NumTag;

int		karc;
int		*tag;
MYREAL		*dx;
MYREAL		*dy;
MYREAL		*dsq;
MYREAL		*d;
MYREAL		*arci;
MYREAL		*arcf;
MYREAL		arcsum;
MYREAL		zres;
MYREAL		zgrid;
MYREAL		xr;
MYREAL		yr;
MYREAL		zr;
MYREAL		ti;
MYREAL		tf;
MYREAL		rr;
MYREAL		rrx2;
MYREAL		rrsq;
MYREAL		area;
MYREAL		rsec2r;
MYREAL		rsecr;
MYREAL		alpha;
MYREAL		beta;
MYREAL		b;
MYREAL		rsec2n;
MYREAL		rsecn;
MYREAL		t;
MYREAL		parea;




/* Initialization */
Num_Layer=(int)(1.0/IntegrationStep+0.5);
Max_Intersection=MIN_INTERSECTION;
NumTag=MIN_TAG;

MaxRadius=0.0;
xmin=99999.9;
ymin=99999.9;
zmin=99999.9;
xmax=-99999.9;
ymax=-99999.9;
zmax=-99999.9;

Array_PdbAtom=MyPdbRec->Atoms;
Num_AllAtom=MyPdbRec->Num_AllAtom;

SurfaceRadius	=(MYREAL *)malloc(sizeof(MYREAL)*Num_AllAtom);
SurfaceRadiusSQR=(MYREAL *)malloc(sizeof(MYREAL)*Num_AllAtom);
access		=(MYREAL *)malloc(sizeof(MYREAL)*Num_AllAtom);
dx		=(MYREAL *)malloc(sizeof(MYREAL)*Num_AllAtom);
dy		=(MYREAL *)malloc(sizeof(MYREAL)*Num_AllAtom);
dsq		=(MYREAL *)malloc(sizeof(MYREAL)*Num_AllAtom);
d		=(MYREAL *)malloc(sizeof(MYREAL)*Num_AllAtom);
arci		=(MYREAL *)malloc(sizeof(MYREAL)*MIN_INTERSECTION);
arcf		=(MYREAL *)malloc(sizeof(MYREAL)*MIN_INTERSECTION);
tag		=(int    *)malloc(sizeof(int   )*MIN_TAG);
if(SurfaceRadius==NULL || SurfaceRadiusSQR==NULL || access==NULL ||
   dx==NULL || dy==NULL || dsq==NULL || d==NULL || arci==NULL ||
   arcf==NULL || tag==NULL ) {
	fprintf(stderr,"\n%s%s: %s\n\n",ERROR_Found,contact_Name,ERROR_MemErr);
	exit(ERROR_Code_MemErr);
	}

for(i=0;i<Num_AllAtom;i++) {
	current_ptr_atom=Array_PdbAtom[i];
	TempDouble=radius[i]+ProbeSize;
	SurfaceRadius[i]=TempDouble;
	SurfaceRadiusSQR[i]=TempDouble * TempDouble;

	current_ptr_atom->SurfaceRadiusSQR=SurfaceRadiusSQR[i];

	MaxRadius=max(MaxRadius,TempDouble);
	xmin=min(xmin,current_ptr_atom->x);
	ymin=min(ymin,current_ptr_atom->y);
	zmin=min(zmin,current_ptr_atom->z);
	xmax=max(xmax,current_ptr_atom->x);
	ymax=max(ymax,current_ptr_atom->y);
	zmax=max(zmax,current_ptr_atom->z);
	}
MaxRadius*=2;




/* Find bounding box for atoms */

// Cubicals containing the atoms are setup. The dimension of an edge equals
// the radius of the largest atom sphere.
// Give an index to each cube.

Num_CubeX=(int)((xmax-xmin)/MaxRadius)+1;
Num_CubeY=(int)((ymax-ymin)/MaxRadius)+1;
Num_CubeZ=(int)((zmax-zmin)/MaxRadius)+1;
// Num_CubeX=max(Num_CubeX,3);
// Num_CubeY=max(Num_CubeY,3);
// Num_CubeZ=max(Num_CubeZ,3);

cubes=(CUBEINFO ***)malloc(sizeof(CUBEINFO **)*Num_CubeX);
atom2cube=(CUBEINFO **)malloc(sizeof(CUBEINFO*) *Num_AllAtom);
if(cubes==NULL || atom2cube==NULL) {
	fprintf(stderr,"\n%s%s: %s\n\n",ERROR_Found,contact_Name,ERROR_MemErr);
	exit(ERROR_Code_MemErr);
	}
for(i=0;i<Num_CubeX;i++) {
	cubes[i]=(CUBEINFO **)malloc(sizeof(CUBEINFO *)*Num_CubeY);
	cubes_LV2=cubes[i];
	if(cubes_LV2==NULL) {
		fprintf(stderr,"\n%s%s: %s\n\n",ERROR_Found,contact_Name,ERROR_MemErr);
		exit(ERROR_Code_MemErr);
		}
	for(j=0;j<Num_CubeY;j++) {
		cubes_LV2[j]=(CUBEINFO *)malloc(sizeof(CUBEINFO)*Num_CubeZ);
		cubes_LV1=cubes_LV2[j];
		if(cubes_LV1==NULL) {
			fprintf(stderr,"\n%s%s: %s\n\n",ERROR_Found,contact_Name,ERROR_MemErr);
			exit(ERROR_Code_MemErr);
			}
		for(k=0;k<Num_CubeZ;k++) {
			current_ptr_cube=cubes_LV1+k;
			current_ptr_cube->Num_Atom=0;
			current_ptr_cube->indexI=i;
			current_ptr_cube->indexJ=j;
			current_ptr_cube->indexK=k;
			current_ptr_cube->Num_NeighborAtom=-1;
			current_ptr_cube->Atom=(PDBATOM **)malloc(sizeof(PDBATOM *) * INC_NEIGHBOR);
			if(current_ptr_cube->Atom==NULL) {
				fprintf(stderr,"\n%s%s: %s\n\n",ERROR_Found,contact_Name,ERROR_MemErr);
				exit(ERROR_Code_MemErr);
				}
			}
		}
	}
			
for(index=0;index<Num_AllAtom;index++) {
	current_ptr_atom=Array_PdbAtom[index];
	i=(int)((current_ptr_atom->x - xmin)/MaxRadius);
	j=(int)((current_ptr_atom->y - ymin)/MaxRadius);
	k=(int)((current_ptr_atom->z - zmin)/MaxRadius);
	current_ptr_cube=&cubes[i][j][k];
	current_ptr_cubeatom=current_ptr_cube->Atom;
	TempInt=current_ptr_cube->Num_Atom;
	if((TempInt % INC_NEIGHBOR)==(INC_NEIGHBOR-1)) {
		current_ptr_cubeatom=(PDBATOM **)realloc(current_ptr_cubeatom,sizeof(PDBATOM *) * INC_NEIGHBOR);
		if(current_ptr_cubeatom==NULL) {
			fprintf(stderr,"\n%s%s: %s\n\n",ERROR_Found,contact_Name,ERROR_MemErr);
			exit(ERROR_Code_MemErr);
			}
		}
	current_ptr_cubeatom[TempInt]=current_ptr_atom;
	current_ptr_cube->Num_Atom ++;
	atom2cube[index]=current_ptr_cube;
	}



/* Process each atom */

for(index=0;index<Num_AllAtom;index++) {
	current_ptr_cube=atom2cube[index];
	area=0.0;
	rr=SurfaceRadius[index];
	rrx2=rr*2.0;
	rrsq=SurfaceRadiusSQR[index];
	current_ptr_atom=Array_PdbAtom[index];
	xr=current_ptr_atom->x;
	yr=current_ptr_atom->y;
	zr=current_ptr_atom->z;

// Find the cubes neighboring the current_ptr_cube cube and record the atoms in these cubes
// if this has NOT been done

	if(current_ptr_cube->Num_NeighborAtom==-1) {
		Num_TempCubes=0;
		for(i=-1;i<=1;i++) {
			TempI= current_ptr_cube->indexI + i;
			if(TempI<0 || TempI>=Num_CubeX) continue;
			for(j=-1;j<=1;j++) {
				TempJ= current_ptr_cube->indexJ + j;
				if(TempJ<0 || TempJ>=Num_CubeY) continue;
				for(k=-1;k<=1;k++) {
					TempK= current_ptr_cube->indexK + k;
					if(TempK<0 || TempK>=Num_CubeZ) continue;
					TempCubes[Num_TempCubes]=&cubes[TempI][TempJ][TempK];
					Num_TempCubes++;
					}
				}
			}
		TempInt=0;
		for(i=0;i<Num_TempCubes;i++) {
			TempInt+=TempCubes[i]->Num_Atom;
			}
		Num_NeighborAtom=TempInt;
		current_ptr_cube->Num_NeighborAtom=TempInt;
		current_ptr_cube->NeighborAtom=(PDBATOM **)malloc(sizeof(PDBATOM *) * TempInt);
		NeighborAtom=current_ptr_cube->NeighborAtom;
		if(NeighborAtom==NULL) {
			fprintf(stderr,"\n%s%s: %s\n\n",ERROR_Found,contact_Name,ERROR_MemErr);
			exit(ERROR_Code_MemErr);
			}
		TempInt2=0;
		for(i=0;i<Num_TempCubes;i++) {
			TempCubes_ptr=TempCubes[i];
			for(j=0;j<TempCubes_ptr->Num_Atom;j++) {
				NeighborAtom[TempInt2]=TempCubes_ptr->Atom[j];
				TempInt2++;
				}
			}
		}
	else	{
		Num_NeighborAtom=current_ptr_cube->Num_NeighborAtom;
		NeighborAtom=current_ptr_cube->NeighborAtom;
		}

// Process the atoms that neighbor atom Array_PdbAtom[index]

	if(Num_NeighborAtom==1) {	// only Array_PdbAtom[index] in the cubes
		area=PIx2 * rrx2;
		goto FINISH_ONE_ATOM;
		}
	for(i=0;i<Num_NeighborAtom;i++) {
		temp_ptr_atom=NeighborAtom[i];
		if(temp_ptr_atom==current_ptr_atom) continue;	// the atom itself
		dx[i]=xr - temp_ptr_atom->x;
		dy[i]=yr - temp_ptr_atom->y;
		dsq[i]=dx[i]*dx[i]+dy[i]*dy[i];
		d[i]=sqrt(dsq[i]);
		}
	zres=rrx2/(MYREAL)Num_Layer;
	zgrid=zr - rr - (zres/2.0);

// Section atom spheres perpendicular to the z axis

	for(i=0;i<Num_Layer;i++) {
		zgrid+=zres;

// Find the radius of the circle of intersection of the target atom sphere on the current z-plane

		rsec2r=rrsq-(zgrid-zr)*(zgrid-zr);
		rsecr=sqrt(rsec2r);
		karc=0;
		for(j=0;j<Num_NeighborAtom;j++) {
			temp_ptr_atom=NeighborAtom[j];
			if(temp_ptr_atom==current_ptr_atom) continue; // the atom itself
			
// Find radius of circle locus

			TempDouble=zgrid - temp_ptr_atom->z;
			rsec2n=temp_ptr_atom->SurfaceRadiusSQR-(TempDouble*TempDouble);
			if(rsec2n<=0.0) continue;
			rsecn=sqrt(rsec2n);

// Find intersections of N.circles with target circles in section

			if(d[j]>=(rsecr+rsecn)) continue;

// Do the circles intersect, or is one circle completely inside the other?

			b=rsecr-rsecn;
			if(b<0.0)
				TempDouble=0.0-b;
			else
				TempDouble=b;
			if(d[j]<=TempDouble) {
				if(b<=0.0) {
					goto FINISH_ONE_LAYER;
					}
				else	{
					continue;
					}
				}
			else	{

// If the circles intersect, find the points of intersection

				karc++;
				if(karc+1>=Max_Intersection) {
					Max_Intersection+=INC_INTERSECTION;
					arci=(MYREAL *)realloc(arci,sizeof(MYREAL)*Max_Intersection);
					arcf=(MYREAL *)realloc(arcf,sizeof(MYREAL)*Max_Intersection);
					if(arci==NULL || arcf==NULL) {
						fprintf(stderr,"\n%s%s: %s\n\n",
							ERROR_Found,contact_Name,ERROR_MemErr);
						exit(ERROR_Code_MemErr);
						}
					}
				arci[karc]=0.0;

// Initial and final arc endpoints are found for the IR circle intersected
// by a neighboring circle contained in the same plane. the initial endpoint
// of the enclosed arc is stored in arci, and the final arc in arcf law of cosines

				alpha=acos((dsq[j]+rsec2r-rsec2n)/(2.0*d[j]*rsecr));

// Alpha is the angle between a line containing a point of intersection and
// the reference circle center and the line containing both circle centers

				beta=atan2(dy[j],dx[j])+PI;

// Beta is the angle between the line containing both circle centers and the
// x-axis

				ti=beta-alpha;
				tf=beta+alpha;
				if(ti<0.0) ti+=(PIx2);
				if(tf>PIx2) tf-=(PIx2);
				arci[karc]=ti;
		
// If the arc crosses zero, then it is broken into two segments.
// the first ends at PIX2 and the second begins at zero

				if(tf<ti) {
					arcf[karc]=PIx2;
					karc++;
					if(karc+1>=Max_Intersection) {
						Max_Intersection+=INC_INTERSECTION;
						arci=(MYREAL *)realloc(arci,sizeof(MYREAL)*Max_Intersection);
						arcf=(MYREAL *)realloc(arcf,sizeof(MYREAL)*Max_Intersection);
						if(arci==NULL || arcf==NULL) {
							fprintf(stderr,"\n%s%s: %s\n\n",
								ERROR_Found,contact_Name,ERROR_MemErr);
							exit(ERROR_Code_MemErr);
							}
						}
					arci[karc]=0.0;
					}
				arcf[karc]=tf;

				}
			}

// Find the accssible contact surface area for the sphere IR on this section

		if (karc==0)
			arcsum=PIx2;
		else	{

// The arc endpoints are sorted on the value of the initial arc endpoint

			if(karc+1>=NumTag) {
				NumTag+=INC_TAG;
				tag=(int *)realloc(tag,sizeof(int)*NumTag);
				}
			sorttag(arci, karc, tag);

// Calculate the accssible area

			arcsum=arci[1];
			t=arcf[tag[1]];
			for(k=2;k<=karc;k++) {
				if(t<arci[k]) arcsum+= (arci[k] - t);
				t=max(t,arcf[tag[k]]);
				}
			arcsum+= (PIx2-t);
			}

// The area/radius is equal to the accssible arc length X the section thickness.

		parea=arcsum*zres;

// Add the accssible area for this atom in this section to the area for this
// atom for all the section encountered thus far

		area+=parea;

FINISH_ONE_LAYER:
		;
		}

FINISH_ONE_ATOM:

// Scale to VDW shell

	access[index]=area * (rr-ProbeSize) * (rr-ProbeSize) / rr;
	}

#ifdef DEBUG
#endif

if(flag_Verbose)
	;
	
free(tag);
free(arci);
free(arcf);
free(dx);
free(dy);
free(dsq);
free(d);
free(SurfaceRadius);
free(SurfaceRadiusSQR);
free(atom2cube);
for(i=0;i<Num_CubeX;i++) {
	for(j=0;j<Num_CubeY;j++) {
		for(k=0;k<Num_CubeZ;k++) {
			if(cubes[i][j][k].Num_NeighborAtom!=-1)
				free(cubes[i][j][k].NeighborAtom);
			free(cubes[i][j][k].Atom);
			}
		free(cubes[i][j]);
		}
	free(cubes[i]);
	}
free(cubes);

return(access);
}




void free_contact(MYREAL *access)
{
free(access);
}


void print_contact(PDBREC *MyPdbRec, MYREAL *access)
{
int i;
PDBATOM		**Array_PdbAtom;
PDBATOM		*current_ptr;

Array_PdbAtom=MyPdbRec->Atoms;

printf("\nNow print accessibility of each atom:\n\n");
for(i=0;i<MyPdbRec->Num_AllAtom;i++) {
	current_ptr=Array_PdbAtom[i];
	if(current_ptr->flag_isatom)
		printf("ATOM  ");
	else
		printf("HETATM");
	printf("%s %s%c",current_ptr->AtomNo,current_ptr->AtomName,current_ptr->AlterLoc);
	printf("%s %c%s   ",current_ptr->ResiduePtr->ResName,
		current_ptr->ResiduePtr->Chain,current_ptr->ResiduePtr->ResNo);
	printf("%8.3f%8.3f%8.3f",current_ptr->x,current_ptr->y,current_ptr->z);
	printf(" %6.2f\n",access[i]);
	}
printf("\n\n");

}

void sorttag(MYREAL *arci, int karc, int *tag)
{
int	i, j, ij, k, m, l;
MYREAL	tg, t, tt;
int	il[16+1], iu[16+1];

for(i=1;i<=karc;i++)
	tag[i]=i;
m=1;
i=1;
j=karc;

Label5:
if(i>=j) goto Label70;

Label10:
k=i;
ij=(j+i)/2;
t=arci[ij];
if(arci[i]<=t) goto Label20;

arci[ij]=arci[i];
arci[i]=t;
t=arci[ij];
tg=tag[ij];
tag[ij]=tag[i];
tag[i]=tg;

Label20:
l=j;
if(arci[j]>=t) goto Label40;

arci[ij]=arci[j];
arci[j]=t;
t=arci[ij];
tg=tag[ij];
tag[ij]=tag[j];
tag[j]=tg;
if(arci[i]<=t) goto Label40;

arci[ij]=arci[i];
arci[i]=t;
t=arci[ij];
tg=tag[ij];
tag[ij]=tag[i];
tag[i]=tg;
goto Label40;

Label30:
arci[l]=arci[k];
arci[k]=tt;
tg=tag[l];
tag[l]=tag[k];
tag[k]=tg;

Label40:
do	{
	l--;
	}	while(arci[l]>t);
tt=arci[l];

Label50:
do	{
	k++;
	}	while(arci[k]<t);
if(k<l) goto Label30;
if(l-i <= j-k) goto Label60;
il[m]=i;
iu[m]=l;
i=k;
m++;
goto Label80;

Label60:
il[m]=k;
iu[m]=j;
j=l;
m++;
goto Label80;

Label70:
m--;
if(m==0) return;
i=il[m];
j=iu[m];

Label80:
if(j-i>=1) goto Label10;
if(i==1) goto Label5;
i--;

Label90:
i++;
if(i==j) goto Label70;
t=arci[i+1];
if(arci[i]<=t) goto Label90;
tg=tag[i+1];
k=i;

Label100:
do	{
	arci[k+1]=arci[k];
	tag[k+1]=tag[k];
	k--;
	}	while(t<arci[k]);
arci[k+1]=t;
tag[k+1]=tg;
goto Label90;

return;
}


void Contact2Acc(MYREAL *access, MYREAL *radius, MYREAL ProbeSize,
			int Num_AllAtom, boolean flag_Verbose)
{
int	i;
MYREAL	TempDouble;

// converts from contact to accessible surface areas (about 3 times larger)
for(i=0;i<Num_AllAtom;i++) {
	TempDouble=radius[i]+ProbeSize;
	access[i]*=(TempDouble*TempDouble/(radius[i]*radius[i]));
	}
}
