/* 规律总结: 
1.在信号灯左转处,没有左转弧线,道路会缺失;在非信号灯双向路左转处,有时候会断开,有时候不会
2.在部分掉头处,导航路径(道路)会缺失
3.连续间隔15分钟访问某tmc,获得step的速度,速度会一直变.
4.最靠近交叉口的tmc速度一天到晚都很低,应该是考虑了信号灯等待时间.
5.有一些小路高德路况为"未知",在官方地图上也未显示,这些小路的速度(路程/时间)会给出一个相对固定的值(比如9km/h)
*/
DROP TABLE SYSTEM.GD_NAV_POINT;
DROP TABLE GD_NAV_TRAFFIC;


/* 第一步 */
--1.1 创建OD点对表, 用于设置导航起终点, 该表可直接在ArcMap中编辑
-- DROP TABLE "XXK"."GD_NAV_POINT" ;
CREATE TABLE "SYSTEM"."GD_NAV_POINT"
   (	"OBJECTID" NUMBER(*,0) NOT NULL ENABLE, 
	"PROJECT" NVARCHAR2(50), 
	"SHAPE" "MDSYS"."SDO_GEOMETRY" , 
	"SE_ANNO_CAD_DATA" BLOB
);



INSERT INTO "SYSTEM"."GD_NAV_POINT"
(OBJECTID, PROJECT, SHAPE, SE_ANNO_CAD_DATA)
VALUES
    (
        1,
        'MyProject',
        SDO_GEOMETRY(
                2001,              -- 表示一个POINT类型
                4326,              -- SRID WGS84坐标系
                SDO_POINT_TYPE(121.212068,31.282072,NULL),
                NULL,
                NULL
        ),
        NULL
    );

INSERT INTO "SYSTEM"."GD_NAV_POINT"
(OBJECTID, PROJECT, SHAPE, SE_ANNO_CAD_DATA)
VALUES
    (
        2,
        'MyProject',
        SDO_GEOMETRY(
                2001,
                4326,
                SDO_POINT_TYPE(121.506098,31.282627,NULL),
                NULL,
                NULL
        ),
        NULL
    );


--修改了1.2 SQL语句的语法格式
CREATE OR REPLACE VIEW v_gd_nav_point AS
SELECT
    TO_CHAR(ROUND(a.shape.sdo_point.x,6))||','||TO_CHAR(ROUND(a.shape.sdo_point.y,6)) AS S,  -- 起点
    TO_CHAR(ROUND(b.shape.sdo_point.x,6))||','||TO_CHAR(ROUND(b.shape.sdo_point.y,6)) AS E   -- 终点
FROM
    GD_NAV_POINT a,
    GD_NAV_POINT b
WHERE
    a.objectid <> b.objectid;



--1.2 生成表GD_NAV_POINT的视图V_GD_NAV_POINT, 按高德接口要求构造起终点坐标, java将直接访问该视图
CREATE OR REPLACE VIEW v_gd_nav_point as
select TO_CHAR(ROUND(a.shape.sdo_point.x,6))||','||TO_CHAR(ROUND(a.shape.sdo_point.y,6)) S, --起点
TO_CHAR(ROUND(b.shape.sdo_point.x,6))||','||TO_CHAR(ROUND(b.shape.sdo_point.y,6)) E,--终点
from GD_NAV_POINT a,GD_NAV_POINT b
where a.objectid <> b.objectid
;
SELECT * FROM v_gd_nav_point;




/* 第二步 */
--2 创建路段表, 用于保存API路段数据
-- drop table GD_NAV_TRAFFIC;
create table GD_NAV_TRAFFIC(
seq number(8) ,
dept varchar2(32),    -- step/tmc
tmcid number(8),     -- 第几个tmc
action varchar2(32),
distance number(8),
duration number(8),
speed number(4),
orientation varchar2(64),
road varchar2(128),
status varchar2(32),
insert_time date,
polyline sdo_geometry
);
-- 创建空间索引
CALL SDOINDEX('GD_NAV_TRAFFIC','polyline',4326);

--修改创建空间索引
INSERT INTO USER_SDO_GEOM_METADATA (
    TABLE_NAME,
    COLUMN_NAME,
    DIMINFO,
    SRID
) VALUES (
             'GD_NAV_TRAFFIC',
             'POLYLINE',
             SDO_DIM_ARRAY(
                     SDO_DIM_ELEMENT('LONGITUDE', 115, 125, 0.00000005),
                     SDO_DIM_ELEMENT('LATITUDE', 30, 35, 0.00000005)
             ),
             4326
         );
CREATE INDEX GD_NAV_TRAFFIC_SIDX
    ON GD_NAV_TRAFFIC(polyline)
    INDEXTYPE IS MDSYS.SPATIAL_INDEX
    PARAMETERS('sdo_indx_dims=2');





