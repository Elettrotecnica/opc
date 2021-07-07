<master>
  <property name="doc(title)">#opc.show_historic_title#</property>
  <property name="context">@context;literal@</property>
  <a href="@csv_url@"
     style="margin-bottom:1%;margin-top:1%;"
     class="btn btn-default"
     title="#opc.download_csv_title#">#opc.download_csv#</a>
  <form method="POST" class="form-inline" action="show-historic">
    <div class="form-group">
      <label for="years">#opc.years#</label>
      <input type="number" min="0" class="form-control" name="years" value="@years@">
    </div>
    <div class="form-group">
      <label for="months">#opc.months#</label>
      <input type="number" min="0" class="form-control" name="months" value="@months@">
    </div>
    <div class="form-group">
      <label for="weeks">#opc.weeks#</label>
      <input type="number" min="0" class="form-control" name="weeks" value="@weeks@">
    </div>
    <div class="form-group">
      <label for="days">#opc.days#</label>
      <input type="number" min="0" class="form-control" name="days" value="@days@">
    </div>
    <button type="submit" class="btn btn-default">OK</button>
  </form>
  <listtemplate name="history"></listtemplate>
