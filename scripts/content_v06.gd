extends RefCounted
const VERSION="0.6.1"
const REGIONS=["余烬维修所","灰闸囚厂","锈脊齿轮井","雾肺水务区","黑棘迁木园","夜血城堡","神笔实验室"]
const STARTS=[11,0,8,18,26,34,42]
const ROSTER=[
	{"name":"凯恩","role":"裂影行者","model":"kain_v04","hp":100.0,"flag":"","skills":["裂影刺","齿刃旋舞","裂影空冲"],"desc":"匕首快攻 / 太刀长斩；煤仓入口宝箱获得太刀。"},
	{"name":"洛铆","role":"机械师","model":"luomao_v04","hp":110.0,"flag":"rescued","skills":["铜核修补击","齿轮过载","机械推进"],"desc":"锤击装甲、修复自身；断电囚门救援。"},
	{"name":"伊瑟","role":"矿族游侠","model":"yise_v04","hp":95.0,"flag":"ranger","skills":["穿甲射击","裂界强弓","游侠空冲"],"desc":"远程弓箭；四层轴承台侧门进入矿牢招募。"},
	{"name":"沈烬","role":"白骨剑客","model":"shenjin_v06","hp":105.0,"flag":"shenjin","skills":["返刃","破阵三叠","踏刃空冲"],"desc":"骨剑连斩、返刃飞剑；水务区折返维修梯招募。"},
	{"name":"纱隐","role":"影织忍者","model":"shayin_v06","hp":90.0,"flag":"shayin","skills":["影缚","影步突袭","烟步空冲"],"desc":"快速双刃、束缚和位移；迁木园双忍藏室招募。"},
	{"name":"维萝","role":"血契炼金术士","model":"weiluo_v06","hp":100.0,"flag":"weiluo","skills":["血瓶回流","赤汞爆裂","雾血空冲"],"desc":"刺剑、血瓶与命中吸血；夜血城堡炼金室招募。"},
	{"name":"零七","role":"电能改造人","model":"zero7_v06","hp":120.0,"flag":"zero7","skills":["电链震击","绝缘护盾","电踏空冲"],"desc":"电能拳刃、群体破势与护盾；实验室活体仓招募。"}
]
const ENEMIES={
	"human":{"model":"kain_v04","hp":65,"human":true},"ranged":{"model":"yise_v04","hp":65,"human":true,"ranged":true},
	"hound":{"model":"mechanical_hound","hp":95},"turret":{"model":"turret_v04","hp":85,"ranged":true},"drone":{"model":"drone_v04","hp":50,"ranged":true,"flying":true},
	"boss":{"model":"execution_machine","hp":480,"boss":true,"flag":"boss","patterns":["落锤","链钩","震地"]},
	"minotaur":{"model":"minotaur_v04","hp":600,"boss":true,"flag":"boss2","patterns":["冲锋","落锤","震地"]},
	"wraith":{"model":"wraith_v06","hp":75,"ranged":true,"flying":true},
	"thorn":{"model":"thorn_v06","hp":105},"blood_guard":{"model":"weiluo_v06","hp":110,"human":true},
	"scribe":{"model":"zero7_v06","hp":100,"human":true,"ranged":true},
	"mother":{"model":"mother_v06","hp":720,"boss":true,"flag":"boss3","patterns":["毒潮","管刺","震地"]},
	"witch":{"model":"witch_v06","hp":760,"boss":true,"flag":"boss4","patterns":["孢弹","根刺","冲锋"]},
	"lord":{"model":"lord_v06","hp":850,"boss":true,"flag":"boss5","patterns":["血矛","冲锋","血潮"]},
	"editor":{"model":"editor_v06","hp":920,"boss":true,"flag":"boss6","patterns":["墨弹","裁稿波","复写突进"]}
}
const QUESTS=[
	{"title":"断电之夜","flag":"boss","region":1,"goal":"救出洛铆、修复钩索，击败链狱典刑机。"},
	{"title":"总井转运表","flag":"boss2","region":2,"goal":"恢复配速井，打倒牛头督工，沿维修桥进入水务区。"},
	{"title":"水下的名字","flag":"boss3","region":3,"goal":"中水位稳定后开蒸汽旁路，再排水；在母体排水室阻止管喉之母。"},
	{"title":"被锁住的根庭","flag":"boss4","region":4,"goal":"引迁木桥至灯位并锁定，学习空冲，击败迁木女巫。"},
	{"title":"自愿之名","flag":"boss5","region":5,"goal":"对齐双镜，取得血契旧账，招募维萝，击败血契侯爵。"},
	{"title":"被删改的记忆","flag":"boss6","region":6,"goal":"复制重块压住双板；断电接分流、冷却、门锁和绝缘，再上电，击败校稿者。"}
]
