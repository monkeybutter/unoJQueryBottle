<!DOCTYPE html>
<html>
  	<head>
      <title>jQuery & Bottle</title>
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <!-- Bootstrap -->
      <link href="/css/bootstrap.min.css" rel="stylesheet" media="screen">
      <!-- JQuery UI -->
      <link href="http://code.jquery.com/ui/1.10.3/themes/smoothness/jquery-ui.css" rel="stylesheet" media="screen">
    </head>

    <style type="text/css">
      h1 {color:red;}
      #X {width: 190px; height: 110px; border: 1px solid #999999; padding: 5px;}
      #wrap {
        width:600px;
        margin:0 auto;
      }
      #left_col {
        float:left;
        width:300px;
      }
      #right_col {
        float:right;
        width:300px;
      }
      #wrap {
        margin: 10px 0;
        font-size: 19.5px;
        line-height: 20px;
        text-rendering: optimizelegibility;
      }

      svg {
        font: 10px sans-serif;
      }

      /*path {
        fill: steelblue;
        opacity: .75;
      }*/

      .class1 {
        fill: steelblue;
        opacity: .55;
      }

      .class2 {
        fill: orange;
        opacity: .55;
      }

      .axis path,
      .axis line {
        fill: none;
        stroke: #000;
        shape-rendering: crispEdges;
      }

      .brush .extent {
        stroke: #fff;
        fill-opacity: .125;
        shape-rendering: crispEdges;
      }

    </style>

    <style type="text/css">

</style>
      
    <!-- JQuery UI JS -->
    <script src="http://code.jquery.com/jquery.js"></script>
    <script src="http://code.jquery.com/ui/1.10.3/jquery-ui.js"></script>
    <script src="/js/d3.v3.js"></script>

    <script>

      $(document).ready(function() {

        $('#Y').change(function() {
          if($('#Y').val() == "MeanDHI"){
            console.log("MeanDHI");
            $('#Algorithm').empty();
            $('#Algorithm').append($('<option></option>').attr('value', 'lr').text('Linear Regression'));
            $('#Algorithm').append($('<option></option>').attr('value', 'rf').text('Random Forest'));
            $('#Algorithm').append($('<option></option>').attr('value', 'br').text('Bayesian Ridge Regression'));
            $('#Algorithm').append($('<option></option>').attr('value', 'ar').text('Auto Regression'));
            $('#Algorithm').append($('<option></option>').attr('value', 'rar').text('Regression + Auto Regression'));
            $('#Algorithm').append($('<option></option>').attr('value', '00').text('No ML'));
          }
          if($('#Y').val() == "MeanGlobalCMP11"){
            console.log("MeanGlobalCMP11");
            $('#Algorithm').empty();
            $('#Algorithm').append($('<option></option>').attr('value', 'lr').text('Linear Regression'));
            $('#Algorithm').append($('<option></option>').attr('value', 'rf').text('Random Forest'));
            $('#Algorithm').append($('<option></option>').attr('value', 'br').text('Bayesian Ridge Regression'));
            $('#Algorithm').append($('<option></option>').attr('value', '00').text('No ML'));
          }
          if($('#Y').val() == "MeanDiffuseCMP11"){
            console.log("MeanDiffuseCMP11");
            $('#Algorithm').empty();
            $('#Algorithm').append($('<option></option>').attr('value', 'lr').text('Linear Regression'));
            $('#Algorithm').append($('<option></option>').attr('value', 'rf').text('Random Forest'));
            $('#Algorithm').append($('<option></option>').attr('value', 'br').text('Bayesian Ridge Regression'));
            $('#Algorithm').append($('<option></option>').attr('value', '00').text('No ML'));
          }
          if($('#Y').val() == "MeanTemperature"){
            console.log("MeanTemperature");
            $('#Algorithm').empty();
            $('#Algorithm').append($('<option></option>').attr('value', 'lr').text('Linear Regression'));
            $('#Algorithm').append($('<option></option>').attr('value', 'rf').text('Random Forest'));
            $('#Algorithm').append($('<option></option>').attr('value', 'br').text('Bayesian Ridge Regression'));
            $('#Algorithm').append($('<option></option>').attr('value', '00').text('No ML'));
          }
          if($('#Y').val() == "MeanPressure"){
            console.log("MeanPressure");
            $('#Algorithm').empty();
            $('#Algorithm').append($('<option></option>').attr('value', 'lr').text('Linear Regression'));
            $('#Algorithm').append($('<option></option>').attr('value', 'rf').text('Random Forest'));
            $('#Algorithm').append($('<option></option>').attr('value', 'br').text('Bayesian Ridge Regression'));
            $('#Algorithm').append($('<option></option>').attr('value', '00').text('No ML'));
          }
        });

        var globalData;

        var MS_PER_MINUTE = 60000; 
        var maxDate = new Date(2013, 1-1, 1);
        var minDate = new Date(2012, 6-1, 1);
        var maxStartDateTraining = new Date(2012, 10-1, 1);
        var minStartDateTraining = new Date(2012, 6-1, 1);
        var dateStartTraining = new Date(minStartDateTraining.getTime());
        var dateEndTraining = new Date(maxStartDateTraining.getTime()); 
        var maxStartDateTest = new Date(2012, 12-1, 31);
        var minStartDateTest = new Date(2012, 10-1, 15);
        var dateStartTest = new Date(minStartDateTest.getTime());
        var dateEndTest = new Date(maxStartDateTest.getTime()); 
        var dateStartZoom;
        var dateEndZoom;


        $( "#slider-range" ).slider({
              range: true,
              min: 0,
              max: Math.floor((maxDate.getTime() - minDate.getTime()) / 86400000),
              values: [ 0, Math.floor((maxStartDateTraining.getTime() - minStartDateTraining.getTime()) / 86400000)],
              change: function( event, ui ) {
                dateStartTraining = new Date(minDate.getTime());
                dateEndTraining = new Date(minDate.getTime());
                dateStartTraining.setDate(dateStartTraining.getDate() + ui.values[0]);
                dateEndTraining.setDate(dateEndTraining.getDate() + ui.values[1]);
                $("#train").val( $.datepicker.formatDate('dd/mm/yy', dateStartTraining) + " - " + $.datepicker.formatDate('dd/mm/yy', dateEndTraining) ); 
              },
              slide: function( event, ui ) {
                dateStartTraining = new Date(minDate.getTime());
                dateEndTraining = new Date(minDate.getTime());
                dateStartTraining.setDate(dateStartTraining.getDate() + ui.values[0]);
                dateEndTraining.setDate(dateEndTraining.getDate() + ui.values[1]);
                $("#train").val( $.datepicker.formatDate('dd/mm/yy', dateStartTraining) + " - " + $.datepicker.formatDate('dd/mm/yy', dateEndTraining) );
              }
        });

        $("#train").val( $.datepicker.formatDate('dd/mm/yy', dateStartTraining) + " - " + $.datepicker.formatDate('dd/mm/yy', dateEndTraining) );

        $( "#slider-range2" ).slider({
              range: true,
              min: 0,
              max: Math.floor((maxDate.getTime() - minDate.getTime()) / 86400000),
              values: [ Math.floor((minStartDateTest.getTime() - minDate.getTime()) / 86400000), Math.floor((maxStartDateTest.getTime() - minDate.getTime()) / 86400000)],
              change: function( event, ui ) {
                dateStartTest = new Date(minDate.getTime());
                dateEndTest = new Date(minDate.getTime());
                dateStartTest.setDate(dateStartTest.getDate() + ui.values[0]);
                dateEndTest.setDate(dateEndTest.getDate() + ui.values[1]);
                $("#test").val( $.datepicker.formatDate('dd/mm/yy', dateStartTest) + " - " + $.datepicker.formatDate('dd/mm/yy', dateEndTest) ); 
              },
              slide: function( event, ui ) {
                dateStartTest = new Date(minDate.getTime());
                dateEndTest = new Date(minDate.getTime());
                dateStartTest.setDate(dateStartTest.getDate() + ui.values[0]);
                dateEndTest.setDate(dateEndTest.getDate() + ui.values[1]);
                $("#test").val( $.datepicker.formatDate('dd/mm/yy', dateStartTest) + " - " + $.datepicker.formatDate('dd/mm/yy', dateEndTest) );
              }
        });

        $("#test").val( $.datepicker.formatDate('dd/mm/yy', dateStartTest) + " - " + $.datepicker.formatDate('dd/mm/yy', dateEndTest) );

        $("#submit").on('click', function(){

          event.preventDefault();

          var data1 = $("#train").val();
          var data2 = $("#test").val();
          var data3 = $("#Y").val();
          var data4 = $("#X").val();
          var data5 = $("#Algorithm").find(":selected").val();

          var Jdata = new Object();
          Jdata.train = data1;
          Jdata.test = data2;
          Jdata.Y = data3;
          Jdata.X = data4;
          Jdata.alg = data5;

          $.ajax({
            url : "/home",
            type : "POST",
            data : JSON.stringify(Jdata),
            contentType : "application/json; charset=utf-8",
            dataType : "json",
            success: function(serverData) {
              $("#rmse").text(serverData["rmse"].toFixed(2));
              $("#mae").text(serverData["mae"].toFixed(2));
              globalData = serverData["plotData"];
              globalData.forEach(function(d) {
                d.date = +d.date;
                d.Y = +d.Y;
                d.Pred = +d.Pred;
              });
              plotData();
            },
            failure: function(errMsg) {
              alert(errMsg);
            }
          });
        });

        function plotData() {

          var margin = {top: 10, right: 10, bottom: 100, left: 40},
              margin2 = {top: 430, right: 10, bottom: 20, left: 40},
              width = 700 - margin.left - margin.right,
              height = 500 - margin.top - margin.bottom,
              height2 = 500 - margin2.top - margin2.bottom;

          var x = d3.time.scale().range([0, width]),
              x2 = d3.time.scale().range([0, width]),
              y = d3.scale.linear().range([height, 0]),
              y2 = d3.scale.linear().range([height2, 0]);

          var xAxis = d3.svg.axis().scale(x).orient("bottom"),
              xAxis2 = d3.svg.axis().scale(x2).orient("bottom"),
              yAxis = d3.svg.axis().scale(y).orient("left");

          var brush = d3.svg.brush()
              .x(x2)
              .on("brush", brushed);

          var area = d3.svg.area()
              .interpolate("monotone")
              .x(function(d) { return x(d.date); })
              .y0(height)
              .y1(function(d) { return y(d.Y); });

          var area2 = d3.svg.area()
              .interpolate("monotone")
              .x(function(d) { return x2(d.date); })
              .y0(height2)
              .y1(function(d) { return y2(d.Y); });

          var Barea = d3.svg.area()
              .interpolate("monotone")
              .x(function(d) { return x(d.date); })
              .y0(height)
              .y1(function(d) { return y(d.Pred); });

          var Barea2 = d3.svg.area()
              .interpolate("monotone")
              .x(function(d) { return x2(d.date); })
              .y0(height2)
              .y1(function(d) { return y2(d.Pred); });

          d3.select("svg").remove();

          var svg = d3.select("#plotPlacer").append("svg")
              .attr("width", width + margin.left + margin.right)
              .attr("height", height + margin.top + margin.bottom);

          svg.append("defs").append("clipPath")
             .attr("id", "clip")
             .append("rect")
             .attr("width", width)
             .attr("height", height);

          var focus = svg.append("g").attr("transform", "translate(" + margin.left + "," + margin.top + ")");

          var context = svg.append("g").attr("transform", "translate(" + margin2.left + "," + margin2.top + ")");

          x.domain(d3.extent(globalData, function(d) { return d.date; }));
          y.domain([0, d3.max(globalData, function(d) { return d.Y; })]);
          x2.domain(x.domain());
          y2.domain(y.domain());

          focus.append("path")
               .datum(globalData)
               .attr("clip-path", "url(#clip)")
               .attr("id", "graph1")
               .attr("class", "class1")
               .attr("d", area);

          focus.append("path")
               .datum(globalData)
               .attr("clip-path", "url(#clip)")
               .attr("id", "graph2")
               .attr("class", "class2")
               .attr("d", Barea);

          focus.append("g")
               .attr("class", "x axis")
               .attr("transform", "translate(0," + height + ")")
               .call(xAxis);

          focus.append("g")
               .attr("class", "y axis")
               .call(yAxis);

          context.append("path")
                 .datum(globalData)
                 .attr("class", "class1")
                 .attr("d", area2);

          context.append("path")
                 .datum(globalData)
                 .attr("class", "class2")
                 .attr("d", Barea2);

          context.append("g")
                 .attr("class", "x axis")
                 .attr("transform", "translate(0," + height2 + ")")
                 .call(xAxis2);

          context.append("g")
                 .attr("class", "x brush")
                 .call(brush)
                 .selectAll("rect")
                 .attr("y", -6)
                 .attr("height", height2 + 7);
    

          function brushed() {
            x.domain(brush.empty() ? x2.domain() : brush.extent());
            focus.select("#graph1").attr("d", area);
            focus.select("#graph2").attr("d", Barea);
            focus.select(".x.axis").call(xAxis);
          }
        }
      });

  	</script>

  	<body>

      <!-- Navbar ================================================== -->
    <div class="navbar navbar-default navbar-fixed-top">
      <div class="container">
        <div class="navbar-header">
          <a href="../" class="navbar-brand">Solar Machine Learning</a>
          <button class="navbar-toggle" type="button" data-toggle="collapse" data-target="#navbar-main">
            <span class="icon-bar"></span>
            <span class="icon-bar"></span>
            <span class="icon-bar"></span>
          </button>
        </div>
        <div class="navbar-collapse collapse" id="navbar-main">
          <ul class="nav navbar-nav">
            <li class="dropdown">
              <a class="dropdown-toggle" data-toggle="dropdown" href="#" id="themes">Themes <span class="caret"></span></a>
              <ul class="dropdown-menu" aria-labelledby="themes">
                <li><a tabindex="-1" href="../default/">Default</a></li>
                <li class="divider"></li>
                <li><a tabindex="-1" href="../amelia/">Amelia</a></li>
                <li><a tabindex="-1" href="../cerulean/">Cerulean</a></li>
                <li><a tabindex="-1" href="../cosmo/">Cosmo</a></li>
                <li><a tabindex="-1" href="../cyborg/">Cyborg</a></li>
                <li><a tabindex="-1" href="../flatly/">Flatly</a></li>
                <li><a tabindex="-1" href="../journal/">Journal</a></li>
                <li><a tabindex="-1" href="../readable/">Readable</a></li>
                <li><a tabindex="-1" href="../simplex/">Simplex</a></li>
                <li><a tabindex="-1" href="../slate/">Slate</a></li>
                <li><a tabindex="-1" href="../spacelab/">Spacelab</a></li>
                <li><a tabindex="-1" href="../united/">United</a></li>
              </ul>
            </li>
            <li>
              <a href="../help/">Help</a>
            </li>
            <li>
              <a href="http://news.bootswatch.com">Blog</a>
            </li>
            <li class="dropdown">
              <a class="dropdown-toggle" data-toggle="dropdown" href="#" id="download">Download <span class="caret"></span></a>
              <ul class="dropdown-menu" aria-labelledby="download">
                <li><a tabindex="-1" href="./bootstrap.min.css">bootstrap.min.css</a></li>
                <li><a tabindex="-1" href="./bootstrap.css">bootstrap.css</a></li>
                <li class="divider"></li>
                <li><a tabindex="-1" href="./variables.less">variables.less</a></li>
                <li><a tabindex="-1" href="./bootswatch.less">bootswatch.less</a></li>
              </ul>
            </li>
          </ul>

          <ul class="nav navbar-nav navbar-right">
            <li><a href="http://builtwithbootstrap.com/" target="_blank">Built With Bootstrap</a></li>
            <li><a href="https://wrapbootstrap.com/?ref=bsw" target="_blank">WrapBootstrap</a></li>
          </ul>

        </div>
      </div>
    </div>

<div class="container">

  <div class="page-header" id="banner">
    <div class="row">
      <div class="col-lg-6">
        <h1>Machine Learning Testbed</h1>
      </div>
    </div>
  </div>


<!-- Masthead
<header class="jumbotron subhead" id="overview">
  <div class="row">
    <div class="span6">
      <h1></h1>
    </div>
  </div>
  <div class="row">
    <div class="span6">
      <h1></h1>
    </div>
  </div>
  <div class="row">
    <div class="span6">
      <h1></h1>
    </div>
  </div>
  ================================================== -->


</header>

<!-- Forms
================================================== -->
<section id="forms">
  <div class="page-header">
    <h3>Data Input</h3>
  </div>

  <div class="row">
    <div class="span10 offset1">

      <form class="well form-search">
        <div class="control-group">
          <label class="control-label" for="select01">Select Forecasted variable:</label>
          <div class="controls">
            <select id="Y">
              <option value="MeanDHI">Direct Horizontal Irradiance</option>
              <option value="MeanGlobalCMP11">Global Solar Irradiance</option>
              <option value="MeanDiffuseCMP11">Diffuse Solar Irradiance</option>
              <option value="MeanTemperature">Temperature</option>
              <option value="MeanPressure">Pressure</option>
            </select>
          </div>
        </div>
      </form>

      <form class="well form-search">
        <div class="control-group">
          <label class="control-label" for="select01">Select ML Algorithm:</label>
          <div class="controls">
            <select id="Algorithm">
              <option value="lr">Linear Regression</option>
              <option value="rf">Random Forest</option>
              <option value="br">Bayesian Ridge Regression</option>
              <option value="ar">Auto Regression</option>
              <option value="rar">Regression + Auto Regression</option>
              <option value="oo">No ML</option>
            </select>
          </div>
        </div>
      </form>

      <form class="well form-search">
        <div class="control-group">
          <label class="control-label" for="select01">Select Model variables:</label>
          <div class="controls">
            <select id="X" multiple>
              <option value="SurfaceSWDirectRad" selected>Direct Horizontal Irradiance</option>
              <option value="SurfaceSWDownRad">Global Solar Irradiance</option>
              <option value="SurfaceSWDiffuseRad">Diffuse Solar Irradiance</option>
              <option value="Temperature2m">Temperature</option>
              <option value="DewPoint2m">Dew Point</option>
              <option value="PressureSurface">Pressure</option>
              <option value="TotalCloudCover">Total Cloud Cover</option>
            </select>
            <p><i>Hold down the Ctrl / Command (Mac) button to select multiple variables.</i></p>
          </div>
        </div>
      </form>

        <form class="well form-search">
          <p>
            <label for="train">Training Date range:</label>
            <input type="text" id="train" class="datefield" style="border: 0; color: #ad1d28; font-weight: bold; width: 190px;" />
          </p>

          <div id="slider-range"></div>
        </form>

        <form class="well form-search">
          <p>
            <label for="test">Testing Date range:</label>
            <input type="text" id="test" class="datefield" style="border: 0; color: #ad1d28; font-weight: bold; width: 190px;" />
          </p>

          <div id="slider-range2"></div>
        </form>


      <form class="form-horizontal well">
        <fieldset>
          <legend>Validate Model</legend>
            <div id="wrap">
              <div id="left_col">
                <button id="submit" type="submit" class="btn btn-primary">Submit</button>
              </div>
              <div id="right_col">
                RMSE: <span id="rmse">-</span><br>
                MAE: <span id="mae">-</span><br>
              </div>
          </div>
        </fieldset>
      </form>
    </div>
  </div>

</section>


<!-- Typography
================================================== -->
<section id="typography">
  <div class="page-header">
    <h3>Plots</h3>
  </div>

  <div class="row">
    <div class="span10 offset1">
      <form class="well form-search">
      <div id="plotPlacer">
      </div>
      </form>
    </div>
  </div>
  
  <div class="row">
    <div class="span6">
      <blockquote>
        <p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Integer posuere erat a ante.</p>
        <small>Someone famous in <cite title="Source Title">Source Title</cite></small>
      </blockquote>
    </div>
    <div class="span6">
      <blockquote class="pull-right">
        <p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Integer posuere erat a ante.</p>
        <small>Someone famous in <cite title="Source Title">Source Title</cite></small>
      </blockquote>
    </div>
  </div>

</section>

     <!-- Footer
      ================================================== -->
      <hr>

      <footer id="footer">
        <p class="pull-right"><a href="#top">Back to top</a></p>
        Developed by <a href="http://www.csiro.au/WERU">CSIRO WERU Group</a>. Contact <a href="mailto:roz016@csiro.au">csiro.au</a>.<br/>
        Based on <a href="http://scikit-learn.org/stable/">SciKit-Learn</a>. <a href="http://www.mongodb.org/‎">MongoDB</a>. <a href="http://d3js.org/‎">D3</a>. <a href="http://bottlepy.org/">Bottle</a>. <a href="http://twitter.github.com/bootstrap/">Bootstrap</a>.</p>
      </footer>

</div><!-- /container -->


	 </body>
</html>