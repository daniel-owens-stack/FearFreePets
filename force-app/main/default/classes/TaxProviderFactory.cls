public with sharing class TaxProviderFactory {
    private static TaxProvider taxProvider;
    private static Map<String, TaxProvider> taxProviders = new Map<String, TaxProvider>();
  
    @testVisible
    private TaxProviderFactory() { }
    
    public static TaxProvider getTaxProvider(TaxMetaData taxMetaData) {
      if (taxProviders.containsKey(taxMetaData.providerImplClass)) {
        taxProvider = taxProviders.get(taxMetaData.providerImplClass);
      } 
      else {
        if (taxMetaData.providerImplClass != null ) {
          Type t = Type.forName(taxMetaData.providerImplClass);
          if(t != null) {
            taxProvider = (TaxProvider) t.newInstance();
          }
          taxProviders.put(taxMetaData.providerImplClass, taxProvider);
        }
      }
      return taxProvider;
    }
  }