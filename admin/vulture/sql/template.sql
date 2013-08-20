INSERT INTO "style_tpl" VALUES(1,'Default','LOGIN','<script type="text/javascript" src="/static/script/jquery-1.8.3.min.js"></script><script type="text/javascript" src="/static/jstree/jquery.jstree.js"></script> <script type="text/javascript"> function crawl(ok_auth, obj){ if (obj.metadata.id in ok_auth){ obj.data.icon = "/static/jstree/vert.png";obj.data.title += " : "+ok_auth[obj.metadata.id] } else if (obj.metadata.op){ obj.state = "open";if (obj.metadata.op=="OR") obj.data.icon = "/static/jstree/u.png"; else obj.data.icon = "/static/jstree/n.png";} else obj.data.icon = "/static/jstree/rouge.png"; if (obj.children) for (var x in obj.children) crawl(ok_auth, obj.children[x]);} function show_auth(ok_auth, todo_auth){ crawl(ok_auth, todo_auth);$.jstree._themes = "/static/jstree/themes/"; $(function () {$("#mytree").jstree({ plugins : [ "themes","json_data","ui",], themes :  {theme:"classic"}, json_data : {"data" :[ todo_auth, ]},});});} function flatten_auth(auth){ if (auth.metadata.op){ if (auth.children.length==1) auth = auth.children[0]; else for (var i in auth.children)auth.children[i] = flatten_auth(auth.children[i])} return auth;}
</script>','<div style="position: absolute; top:25%; left:25%;">
<div id="custom">
<h4>__ERRORS__</h4>
__FORM__
<div id="mytree" class="ctree"></div>
<script type="text/javascript" class="source">
__LOGGED_AUTH__
show_auth(ok_auth, flatten_auth(todo_auth))
</script>
</div></div>');
INSERT INTO "style_tpl" VALUES(2,'portal','PORTAL','','<div>
Bienvenue <strong>__LOGIN_NAME__ </strong> (
<a href="/logout">Logout</a> )
</div>
<div>
__APPS__
</div>');
INSERT INTO "style_tpl" VALUES(3,'Login-InWebo','LOGIN','<style> a{ text-decoration: none; font-weight: bold;color: green; }</style>
<script type="text/javascript" src="https://ult-inwebo.com/config/iwconfig.js"></script>
<script type="text/javascript" src="https://ult-inwebo.com/webapp/js/helium.min.js"></script>
<script src="/static/script/jquery-1.8.3.min.js"></script>
<script type="text/javascript">
$(document).ready(function() {
        if ($("#inweboAuth").length) {
                start_helium("inweboAuth",
                        function(iw,data){ if (data.result == "ok") { iw.insertFields(data); }
                                if (data.result == "nok" && data.error == "no_profile")
                                { start_helium("inweboActivate"); }})
        }})
</script>','<center>
<div style = "position: absolute; top:25%; left:25%;">
<div id="custom" style="margin: 0; padding: 60 30;">
<h3>Vulture by InWebo</h3>
<h2><font color="red">__ERRORS__</font></h2>
__FORM__
<a href="javascript:start_helium(\"inweboActivate\")">Enrôler mon navigateur dans Helium</a>
<br>
<a href="javascript:start_helium(\"inweboAuth\")">Se connecter avec Helium</a>
</div>
</div>
<div id="inweboAuth" action="authenticate" lang="fr"
alias="1234" style="display:none"></div> <div id="inweboActivate" action="activate" lang="fr"
alias="1234" style="display:none"></div>
</center>');
INSERT INTO "style_tpl" VALUES(5,'portal + change pass','PORTAL','<script src="/static/script/jquery-1.8.3.min.js"></script>
<style>
#chpass_result { font-size: medium; font-weight: bold }
#chpass_box { 
		background-color: #white; 
		text-decoration:none;
		font-family: arial; 
		font-color: black; 
		float:right; 
		border: 1px solid black;
	}
#chpass_lnk {}
.result_fail { background-color: #Ff7575 }
.result_success { background-color: #76FF76 }
a { color: inherit;text-decoration: none; }
</style>
<script>
	var CHPASS_URL = "/changepass";
	var CHPASS_OK = "Password successfully changed";
	var CHPASS_FAIL = "Password was not changed";
	
	var chpass_visible = true;
	function show_chpass(){
		if (chpass_visible){
			$("#chpass_div").hide()
		}else{
			var res = $("#chpass_result");
			$("#chpass_div").show()
			res.text("");
			res.removeClass();
		}
		chpass_visible^=true;
	}
	var x;
	function changepass_success(result){
		var msg;
		var res_box = $("#chpass_result");
		res_box.removeClass();
		if (result.success){
			res_box.addClass("result_success");
			res_box.text(CHPASS_OK);
		}
		else{
			res_box.addClass("result_fail");
			res_box.text(CHPASS_FAIL);
		}
		
	}
	function connect_error(){
		$("#chpass_result").text("network error"); 
	}
	
	function submit_chpass(){
		$.ajax({
			type: ''POST'', 
			url: CHPASS_URL,
			data: {
				''vulture_login'':$("#vuser").val(),
				''vulture_password'':$("#vpass").val(),
				''vulture_newpass1'':$("#vnpass1").val(),
				''vulture_newpass2'':$("#vnpass2").val(),
			},
			success: changepass_success,
			error: function(){alert("nicht")},
			dataType: "json",
		});
	}
	function startup(){
		show_chpass();
		$("#chpass_form").bind(''submit'', function(e){e.preventDefault();submit_chpass()});
	}
	$(document).ready(startup);
</script>','<div>
Bienvenue <strong>__LOGIN_NAME__ </strong> (
<a href="/logout">Logout</a> )
</div>
<div id="chpass_box">
	<div id="chpass_div" style="display:none">
		<form id="chpass_form">
			<table>
				<thead>
					<tr><th colspan="2" id="chpass_result"></th></tr>
				</thead>
				<tbody>
					<tr>
						<td><label for="vulture_login">Username</label></td>
						<td><input id="vuser" name="vulture_login" type="text"/></td>
					</tr>
					<tr>
						<td><label for="vulture_password">Password</label></td>
						<td><input id="vpass" name="vulture_password" type="password"/></td>
					</tr>
					<tr>
						<td><label for="vulture_newpass1">New password</label></td>
						<td><input id="vnpass1" name="vulture_newpass1" type="password"/></td>
					</tr>
					<tr>
						<td><label for="vulture_newpass2">Confirm password</label></td>
						<td><input id="vnpass2" name="vulture_newpass2" type="password"/></td>
					</tr>
					<tr>
						<td></td>
						<td><input type="submit" value="Submit"/></td>
					</tr>
				</tbody>
			</table>
		</form>
	</div>
	<a id="chpass_lnk" onclick="show_chpass()">Change password &gt;&gt;</a>
</div>
<div>
__APPS__
</div>');
