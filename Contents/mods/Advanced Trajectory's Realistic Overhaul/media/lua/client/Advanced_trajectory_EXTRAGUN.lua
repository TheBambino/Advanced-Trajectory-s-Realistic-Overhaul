require "Advanced_trajectory_core"

--范例 添加特殊的枪械


--         item,                                      --1物品obj
--         square,                                    --2方格obj
--         {deltX,deltY},                             --3向量
--         {offx, offy, offz},                        --4偏移量
--         dirc,                                      --5方向
--         _damage,                                   --6伤害
--         ballisticdistance,                         --7距离
--         winddir,                                   --8弹道小类别
--         weaponname,                                --9种类
--         rollspeed,                                 --10旋转速度
--         iscanthrough,                              --11是否能够穿透
--         ballisticspeed,                            --12弹道速度
--         iscanbigger,                               --13是否可以变大
--         sfxname,                                   --14弹道名称
--         isthroughwall,                             --15是否能穿墙
--         1,                                         --16尺寸
--         0,                                         --17当前距离
--         distancez,                                 --18距离常数
--         player,                                    --19玩家
--         {offx, offy, offz},                        --20原始偏移量
--         0,                                         --21计数 
--         throwinfo                                  --22投掷物属性    




--"Base.examplegun"
local mygun = {}

mygun[4] = {0.75,0.75,0.45}
mygun[9] = "revolver"
mygun[11] = true
mygun[12] = 16
mygun[14] = "Base.revolversfx"

Advanced_trajectory.Advanced_trajectory["Base.examplegun"] = mygun
