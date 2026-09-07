"""Bake volume-safe Magma leg corrections into the exported clip keys.
Foot targets in this authoring pass are skeleton-space. The runtime adds
world-space stance locking against actual rendered support surfaces.
"""
import math
import numpy as np


def matrix(q):
    x,y,z,w=q
    return np.array([[1-2*(y*y+z*z),2*(x*y-z*w),2*(x*z+y*w)],
                     [2*(x*y+z*w),1-2*(x*x+z*z),2*(y*z-x*w)],
                     [2*(x*z-y*w),2*(y*z+x*w),1-2*(x*x+y*y)]])


def quaternion(m):
    # Largest diagonal branch avoids precision loss around half turns.
    trace=np.trace(m)
    if trace > 0:
        s=math.sqrt(trace+1)*2
        q=[(m[2,1]-m[1,2])/s,(m[0,2]-m[2,0])/s,(m[1,0]-m[0,1])/s,s/4]
    else:
        i=int(np.argmax(np.diag(m))); j=(i+1)%3; k=(i+2)%3
        s=math.sqrt(max(0,1+m[i,i]-m[j,j]-m[k,k]))*2
        q=[0.,0.,0.,(m[k,j]-m[j,k])/s];q[i]=s/4;q[j]=(m[i,j]+m[j,i])/s;q[k]=(m[i,k]+m[k,i])/s
    return (np.array(q)/np.linalg.norm(q)).tolist()


def between(a,b):
    a=a/np.linalg.norm(a); b=b/np.linalg.norm(b)
    q=np.r_[np.cross(a,b),1+np.dot(a,b)]
    if np.linalg.norm(q)<1e-7:
        axis=np.cross(a,[1,0,0] if abs(a[0])<.8 else [0,1,0]);q=np.r_[axis,0.]
    return matrix(q/np.linalg.norm(q))


def correct(m, euler_quat):
    lookup={n:i for i,(n,_,_) in enumerate(m.bones)}
    def transforms(pose):
        out=[]
        for name,pos,parent in m.bones:
            r,off=pose.get(name,([0,0,0],[0,0,0]))
            local=np.eye(4);local[:3,:3]=matrix(euler_quat(r) if len(r)==3 else r)
            local[:3,3]=pos-(m.bones[parent][1] if parent is not None else 0)+off
            out.append(local if parent is None else out[parent]@local)
        return out
    def rotate(pose,i,global_rot):
        trans=transforms(pose); name,_,parent=m.bones[i]
        rot=global_rot if parent is None else trans[parent][:3,:3].T@global_rot
        pose[name]=(quaternion(rot),pose.get(name,([0,0,0],[0,0,0]))[1])
    for clip,(times,poses) in m.animations.items():
        if clip=='defeat':
            continue # A falling actor must not have its feet pinned into a standing pose.
        for t,pose in zip(times,poses):
            for side,sign,shift in [('L',-1,0),('R',1,.5)]:
                a,b,c=[lookup[n+'.'+side] for n in ['Thigh','Hock','Foot']]
                target=m.bones[c][1].copy()
                if clip=='walk':
                    p=(t/.8+shift)%1
                    if p<.5:
                        target[2]+=-.475+.95*(p/.5)
                    else:
                        q=(p-.5)/.5;ease=q*q*(3-2*q)
                        target[2]+=.475-.95*ease;target[1]+=.16*math.sin(math.pi*q)
                trs=transforms(pose);hip,knee,foot=[trs[i][:3,3] for i in [a,b,c]]
                upper=np.linalg.norm(knee-hip);lower=np.linalg.norm(foot-knee)
                d=target-hip;length=np.clip(np.linalg.norm(d),abs(upper-lower)+.001,upper+lower-.001);axis=d/np.linalg.norm(d)
                pole=np.array([sign*.28,0,-1]);pole-=axis*np.dot(pole,axis);pole/=np.linalg.norm(pole)
                along=(upper*upper-lower*lower+length*length)/(2*length)
                elbow=hip+axis*along+pole*math.sqrt(max(0,upper*upper-along*along))
                # Preserve the exact bind pose for idle at t=0, as required by skin diagnostics.
                if clip=='idle' and (abs(t)<1e-9 or abs(t-1.8)<1e-9):
                    continue
                rotate(pose,a,between(knee-hip,elbow-hip)@trs[a][:3,:3])
                trs=transforms(pose);knee,foot=[trs[i][:3,3] for i in [b,c]]
                rotate(pose,b,between(foot-knee,hip+axis*length-knee)@trs[b][:3,:3])
                rotate(pose,c,np.eye(3))
